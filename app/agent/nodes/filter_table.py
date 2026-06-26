import yaml
from langchain_core.output_parsers import JsonOutputParser
from langchain_core.prompts import PromptTemplate
from langgraph.runtime import Runtime

from app.agent.context import DataAgentContext
from app.agent.llm import llm
from app.agent.state import DataAgentState, TableInfoState
from app.core.log import logger
from app.prompt.prompt_loader import loader_prompt


async def filter_table(state: DataAgentState, runtime: Runtime[DataAgentContext]):
    writer = runtime.stream_writer
    writer({"stage": "过滤表信息"})
    try:
        query = state["query"]
        table_infos: list[TableInfoState] = state["table_infos"]

        tml = await loader_prompt("filter_table_info")
        prompt = PromptTemplate(template=tml, input_variables=["query", "table_infos"])
        output_parser = JsonOutputParser()
        chain = prompt | llm | output_parser
        result = await chain.ainvoke({
            "query": query,
            "table_infos": yaml.dump(table_infos, allow_unicode=True, sort_keys=False)
        })
        logger.info(f"表信息过滤后的结果：{result}")

        for table_info in table_infos[:]:
            table_name = table_info["name"]
            if table_name not in result:
                table_infos.remove(table_info)
            else:
                for column in table_info["columns"][:]:
                    column_name = column["name"]
                    if column_name not in result[table_name]:
                        table_info["columns"].remove(column)

        logger.info(f"过滤后的表信息：{[t['name'] for t in table_infos]}")
        return {"table_infos": table_infos}
    except Exception as e:
        logger.error(f"过滤表信息异常：{str(e)}")
        raise
