from langchain_core.output_parsers import JsonOutputParser
from langchain_core.prompts import PromptTemplate
from langgraph.runtime import Runtime

from app.agent.context import DataAgentContext
from app.agent.llm import llm
from app.agent.state import DataAgentState
from app.core.log import logger
from app.models.qdrant.metric_info_qdrant import MetricInfoQdrant
from app.prompt.prompt_loader import loader_prompt


async def recall_metric(state: DataAgentState, runtime: Runtime[DataAgentContext]):
    writer = runtime.stream_writer
    writer({"stage": "召回指标信息"})
    try:
        embeddings = runtime.context["embeddings"]
        metric_qdrant_repository = runtime.context["metric_qdrant_repository"]
        query = state["query"]
        keywords = state["keywords"]

        tml = await loader_prompt("extend_keywords_for_metric_recall")
        prompt = PromptTemplate(template=tml, input_variables=["query"])
        output_parser = JsonOutputParser()
        chain = prompt | llm | output_parser
        result = await chain.ainvoke({"query": query})
        keywords = set(keywords + result)
        logger.info(f"指标扩展后关键字列表：{keywords}")

        retrieved_metric_map: dict[str, MetricInfoQdrant] = {}
        for keyword in keywords:
            embedding = await embeddings.aembed_query(keyword)
            payloads: list = await metric_qdrant_repository.search(embedding)
            for payload in payloads:
                metric_id = payload["id"]
                if metric_id not in retrieved_metric_map:
                    retrieved_metric_map[metric_id] = payload

        retrieved_metrics = list(retrieved_metric_map.values())
        logger.info(f"召回指标信息成功：{list(retrieved_metric_map.keys())}")
        return {"retrieved_metrics": retrieved_metrics}
    except Exception as e:
        logger.error(f"召回指标信息异常：{str(e)}")
        raise
