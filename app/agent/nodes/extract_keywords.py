import jieba.analyse
from langgraph.runtime import Runtime

from app.agent.context import DataAgentContext
from app.agent.state import DataAgentState
from app.core.log import logger


async def extract_keywords(state: DataAgentState, runtime: Runtime[DataAgentContext]):
    writer = runtime.stream_writer
    writer({"stage": "提取关键字"})
    try:
        query = state["query"]
        allowPOS = (
            "n", "nr", "ns", "nt", "nz", "v", "vn", "a", "an",
            "eng", "i", "l",
        )
        keywords = jieba.analyse.extract_tags(query, allowPOS=allowPOS)
        # 避免分词后缺失语义，将原问题也加入
        keywords = list(set(keywords + [query]))
        logger.info(f"提取关键字成功：{keywords}")
        return {"keywords": keywords}
    except Exception as e:
        logger.error(f"提取关键字异常：{str(e)}")
        raise
