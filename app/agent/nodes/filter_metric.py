import yaml
from langchain_core.output_parsers import JsonOutputParser
from langchain_core.prompts import PromptTemplate
from langgraph.runtime import Runtime

from app.agent.context import DataAgentContext
from app.agent.llm import llm
from app.agent.state import DataAgentState, MetricInfoState
from app.core.log import logger
from app.prompt.prompt_loader import loader_prompt


async def filter_metric(state: DataAgentState, runtime: Runtime[DataAgentContext]):
    writer = runtime.stream_writer
    writer({"stage": "过滤指标信息"})
    try:
        query = state["query"]
        metric_infos: list[MetricInfoState] = state["metric_infos"]

        tml = await loader_prompt("filter_metric_info")
        prompt = PromptTemplate(template=tml, input_variables=["query", "metric_infos"])
        output_parser = JsonOutputParser()
        chain = prompt | llm | output_parser
        result = await chain.ainvoke({
            "query": query,
            "metric_infos": yaml.dump(metric_infos, allow_unicode=True, sort_keys=False)
        })
        logger.info(f"指标信息过滤后的结果：{result}")

        for metric_info in metric_infos[:]:
            if metric_info['name'] not in result:
                metric_infos.remove(metric_info)

        logger.info(f"过滤后的指标信息：{[m['name'] for m in metric_infos]}")
        return {"metric_infos": metric_infos}
    except Exception as e:
        logger.error(f"过滤指标信息异常：{str(e)}")
        raise
