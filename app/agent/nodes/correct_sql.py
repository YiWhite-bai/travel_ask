import yaml
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import PromptTemplate
from langgraph.runtime import Runtime

from app.agent.context import DataAgentContext
from app.agent.llm import llm
from app.agent.state import DataAgentState, TableInfoState, MetricInfoState
from app.core.log import logger
from app.prompt.prompt_loader import loader_prompt


async def correct_sql(state: DataAgentState, runtime: Runtime[DataAgentContext]):
    writer = runtime.stream_writer
    writer({"stage": "校正sql语句"})
    try:
        query: str = state["query"]
        table_infos: list[TableInfoState] = state["table_infos"]
        metric_infos: list[MetricInfoState] = state["metric_infos"]
        date_info = state["date_info"]
        db_info = state["db_info"]
        error = state["error"]
        sql = state["sql"]

        tml = await loader_prompt("correct_sql")
        prompt = PromptTemplate(
            template=tml,
            input_variables=["query", "table_infos", "metric_infos", "date_info", "db_info", "error", "sql"]
        )
        output_parser = StrOutputParser()
        chain = prompt | llm | output_parser
        sql = await chain.ainvoke({
            "query": query,
            "table_infos": yaml.dump(table_infos, allow_unicode=True, sort_keys=False),
            "metric_infos": yaml.dump(metric_infos, allow_unicode=True, sort_keys=False),
            "date_info": yaml.dump(date_info, allow_unicode=True, sort_keys=False),
            "db_info": yaml.dump(db_info, allow_unicode=True, sort_keys=False),
            "error": error,
            "sql": sql
        })

        logger.info(f"校正后的sql语句：\n{sql}")
        return {"sql": sql}
    except Exception as e:
        logger.error(f"校正sql异常：{str(e)}")
        raise
