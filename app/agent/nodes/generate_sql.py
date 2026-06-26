import yaml
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import PromptTemplate
from langgraph.runtime import Runtime

from app.agent.context import DataAgentContext
from app.agent.llm import llm
from app.agent.state import DataAgentState, TableInfoState, MetricInfoState
from app.core.log import logger
from app.prompt.prompt_loader import loader_prompt


async def generate_sql(state: DataAgentState, runtime: Runtime[DataAgentContext]):
    writer = runtime.stream_writer
    writer({"stage": "生成sql语句"})
    try:
        query: str = state["query"]
        table_infos: list[TableInfoState] = state["table_infos"]
        metric_infos: list[MetricInfoState] = state["metric_infos"]
        date_info = state["date_info"]
        db_info = state["db_info"]

        tml = await loader_prompt("generate_sql")
        prompt = PromptTemplate(
            template=tml,
            input_variables=["query", "table_infos", "metric_infos", "date_info", "db_info"]
        )
        output_parser = StrOutputParser()
        chain = prompt | llm | output_parser
        sql = await chain.ainvoke({
            "query": query,
            "table_infos": yaml.dump(table_infos, allow_unicode=True, sort_keys=False),
            "metric_infos": yaml.dump(metric_infos, allow_unicode=True, sort_keys=False),
            "date_info": yaml.dump(date_info, allow_unicode=True, sort_keys=False),
            "db_info": yaml.dump(db_info, allow_unicode=True, sort_keys=False),
        })

        # LLM 判定无法用已有数据回答
        if sql and "NO_SUITABLE_DATA" in sql:
            logger.info(f"LLM判定用户问题无法用已有数据回答，query: {query}")
            writer({"no_data": True, "message": "抱歉，当前数据库中暂无该问题的相关数据，请尝试询问旅游业务有关的问题（如景区、酒店、机票、火车票、订单等）。"})
            return {"sql": "SELECT 1 WHERE 1=0"}

        logger.info(f"生成的sql语句：\n{sql}")
        return {"sql": sql}
    except Exception as e:
        logger.error(f"生成sql异常：{str(e)}")
        raise
