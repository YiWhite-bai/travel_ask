from langgraph.runtime import Runtime

from app.agent.context import DataAgentContext
from app.agent.state import DataAgentState
from app.core.log import logger


async def execute_sql(state: DataAgentState, runtime: Runtime[DataAgentContext]):
    writer = runtime.stream_writer
    writer({"stage": "执行sql语句"})
    try:
        dw_mysql_repository = runtime.context["dw_mysql_repository"]
        sql = state["sql"]
        result = await dw_mysql_repository.execute_sql(sql)
        if result:
            writer({"result": result})
            logger.info(f"执行sql成功，结果行数：{len(result)}")
        else:
            writer({"empty": True, "message": "未查到匹配的数据，请尝试换个说法或扩大查询范围。"})
            logger.info(f"执行sql成功，但结果为空")
    except Exception as e:
        err_msg = str(e)
        logger.error(f"执行sql异常：{err_msg}")
        # 判断是否是不存在的表
        if "doesn't exist" in err_msg or "does not exist" in err_msg or "1146" in err_msg:
            writer({"empty": True, "message": "抱歉，数据库中没有相关的数据表，我暂时无法回答这个问题。请换个话题试试吧！"})
        else:
            writer({"error": f"查询执行失败：{err_msg}"})
