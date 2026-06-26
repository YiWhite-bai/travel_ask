from langchain_core.output_parsers import JsonOutputParser
from langchain_core.prompts import PromptTemplate
from langgraph.runtime import Runtime

from app.agent.context import DataAgentContext
from app.agent.llm import llm
from app.agent.state import DataAgentState
from app.core.log import logger
from app.models.qdrant.column_info_qdrant import ColumnInfoQdrant
from app.prompt.prompt_loader import loader_prompt


async def recall_column(state: DataAgentState, runtime: Runtime[DataAgentContext]):
    writer = runtime.stream_writer
    writer({"stage": "召回字段信息"})
    try:
        embeddings = runtime.context["embeddings"]
        column_qdrant_repository = runtime.context["column_qdrant_repository"]
        query = state["query"]
        keywords = state["keywords"]

        # LLM扩展关键词
        tml = await loader_prompt("extend_keywords_for_column_recall")
        prompt = PromptTemplate(template=tml, input_variables=["query"])
        output_parser = JsonOutputParser()
        chain = prompt | llm | output_parser
        result = await chain.ainvoke({"query": query})
        keywords = set(keywords + result)
        logger.info(f"字段扩展后关键字列表：{keywords}")

        # Qdrant召回字段
        retrieved_column_map: dict[str, ColumnInfoQdrant] = {}
        for keyword in keywords:
            embedding = await embeddings.aembed_query(keyword)
            payloads: list = await column_qdrant_repository.search(embedding)
            for payload in payloads:
                column_id = payload["id"]
                if column_id not in retrieved_column_map:
                    retrieved_column_map[column_id] = payload

        retrieved_columns = list(retrieved_column_map.values())
        logger.info(f"召回字段信息成功：{list(retrieved_column_map.keys())}")
        return {"retrieved_columns": retrieved_columns}
    except Exception as e:
        logger.error(f"召回字段信息异常：{str(e)}")
        raise
