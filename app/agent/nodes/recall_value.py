from langchain_core.output_parsers import JsonOutputParser
from langchain_core.prompts import PromptTemplate
from langgraph.runtime import Runtime

from app.agent.context import DataAgentContext
from app.agent.llm import llm
from app.agent.state import DataAgentState
from app.core.log import logger
from app.models.es.value_info_es import ValueInfoEs
from app.prompt.prompt_loader import loader_prompt


async def recall_value(state: DataAgentState, runtime: Runtime[DataAgentContext]):
    writer = runtime.stream_writer
    writer({"stage": "召回字段取值"})
    try:
        query = state["query"]
        keywords = state["keywords"]
        value_es_repository = runtime.context["value_es_repository"]

        tml = await loader_prompt("extend_keywords_for_value_recall")
        prompt = PromptTemplate(template=tml, input_variables=["query"])
        output_parser = JsonOutputParser()
        chain = prompt | llm | output_parser
        result = await chain.ainvoke({"query": query})
        keywords = set(keywords + result)
        logger.info(f"取值扩展后关键字列表：{keywords}")

        retrieved_value_map: dict[str, ValueInfoEs] = {}
        for keyword in keywords:
            values: list = await value_es_repository.search(keyword)
            if values:
                for value in values:
                    value_id = value["id"]
                    if value_id not in retrieved_value_map:
                        retrieved_value_map[value_id] = value

        retrieved_values = list(retrieved_value_map.values())
        logger.info(f"召回字段取值成功：{list(retrieved_value_map.keys())}")
        return {"retrieved_values": retrieved_values}
    except Exception as e:
        logger.error(f"召回字段取值异常：{str(e)}")
        raise
