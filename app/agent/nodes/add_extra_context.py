from datetime import datetime

from langgraph.runtime import Runtime

from app.agent.context import DataAgentContext
from app.agent.state import DataAgentState, DateInfoState
from app.core.log import logger


async def add_extra_context(state: DataAgentState, runtime: Runtime[DataAgentContext]):
    writer = runtime.stream_writer
    writer({"stage": "添加额外上下文"})
    try:
        dw_mysql_repository = runtime.context["dw_mysql_repository"]

        today = datetime.today()
        date = today.strftime("%Y-%m-%d")
        weekday = today.strftime("%A")
        month = today.month
        quarter = f"Q{(month - 1) // 3 + 1}"
        date_info_state = DateInfoState(date=date, weekday=weekday, quarter=quarter)

        db_info: dict = await dw_mysql_repository.get_db_info()
        logger.info(f"额外上下文信息添加，日期信息：{date_info_state}，数据库信息：{db_info}")
        return {"date_info": date_info_state, "db_info": db_info}
    except Exception as e:
        logger.error(f"添加额外上下文信息异常：{str(e)}")
        raise
