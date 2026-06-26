import asyncio
from typing import List, Optional

import httpx
from langchain_core.embeddings import Embeddings

from app.conf.app_config import app_config, EmbeddingConfig


class TEIEmbeddings(Embeddings):
    """简易 TEI (Text Embeddings Inference) 客户端，绕过 langchain-huggingface 版本兼容问题，
    直接通过 HTTP 调用 TEI 服务的 /embed 接口。"""

    def __init__(self, endpoint_url: str):
        self.endpoint_url = endpoint_url.rstrip("/")
        self._client: Optional[httpx.AsyncClient] = None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None:
            self._client = httpx.AsyncClient(timeout=httpx.Timeout(60.0))
        return self._client

    async def aembed_query(self, text: str) -> List[float]:
        """将单个查询文本转换为向量"""
        embeddings = await self.aembed_documents([text])
        return embeddings[0]

    async def aembed_documents(self, texts: List[str]) -> List[List[float]]:
        """逐个请求嵌入（CPU 版 TEI 不支持真正并发，并发会打爆队列导致 panic）"""
        import asyncio as _asyncio

        client = await self._get_client()
        results = []

        for i, text in enumerate(texts):
            last_err = None
            for attempt in range(3):
                try:
                    resp = await client.post(
                        f"{self.endpoint_url}/embed",
                        json={"inputs": text},
                        headers={"Content-Type": "application/json"},
                    )
                    resp.raise_for_status()
                    data = resp.json()
                    if isinstance(data, list) and len(data) == 1 and isinstance(data[0], list):
                        results.append(data[0])
                    elif isinstance(data, list) and len(data) > 0 and isinstance(data[0], float):
                        results.append(data)
                    else:
                        results.append(data[0] if isinstance(data, list) else data)
                    break
                except Exception as e:
                    last_err = e
                    await _asyncio.sleep(2.0 * (attempt + 1))  # 退避等 TEI 恢复
            else:
                raise last_err

            # 每 10 条打印进度，每请求间隔 100ms 防止队列堆积
            if (i + 1) % 10 == 0:
                from app.core.log import logger
                logger.info(f"Embedding progress: {i + 1}/{len(texts)}")
            await _asyncio.sleep(0.1)

        return results

    def embed_query(self, text: str) -> List[float]:
        return asyncio.run(self.aembed_query(text))

    def embed_documents(self, texts: List[str]) -> List[List[float]]:
        return asyncio.run(self.aembed_documents(texts))

    async def close(self):
        if self._client:
            await self._client.aclose()


class EmbeddingClientManager:
    def __init__(self, config: EmbeddingConfig):
        self.embeddings: Optional[TEIEmbeddings] = None
        self.config = config

    def _get_url(self):
        return f"http://{self.config.host}:{self.config.port}"

    def init(self):
        self.embeddings = TEIEmbeddings(endpoint_url=self._get_url())

    async def close(self):
        if self.embeddings:
            await self.embeddings.close()


embedding_client_manager = EmbeddingClientManager(app_config.embedding)
