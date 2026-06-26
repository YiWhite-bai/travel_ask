from qdrant_client import AsyncQdrantClient, models

from app.conf.app_config import app_config
from app.models.qdrant.metric_info_qdrant import MetricInfoQdrant


class MetricQdrantRepository:
    collection_name = "data-agent-metric"

    def __init__(self, client: AsyncQdrantClient):
        self.client = client

    async def ensure_collection(self):
        if not await self.client.collection_exists(collection_name=self.collection_name):
            await self.client.create_collection(
                collection_name=self.collection_name,
                vectors_config=models.VectorParams(
                    size=app_config.qdrant.embedding_size,
                    distance=models.Distance.COSINE
                ),
            )

    async def upsert_metric(self, ids: list[str], embeddings: list[list[float]],
                            payloads: list[MetricInfoQdrant], batch_size: int = 10):
        zipped = list(zip(ids, embeddings, payloads))
        for i in range(0, len(zipped), batch_size):
            batch_zipped = zipped[i:i + batch_size]
            points = [
                models.PointStruct(id=id, payload=payload, vector=embedding)
                for id, embedding, payload in batch_zipped
            ]
            await self.client.upsert(collection_name=self.collection_name, points=points)

    async def search(self, embedding: list[float], score_threshold: float = 0.6) -> list:
        points = await self.client.query_points(
            collection_name=self.collection_name,
            query=embedding,
            score_threshold=score_threshold
        )
        return [point.payload for point in points.points]
