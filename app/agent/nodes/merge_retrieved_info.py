from langgraph.runtime import Runtime

from app.agent.context import DataAgentContext
from app.agent.state import DataAgentState, TableInfoState, ColumnInfoState, MetricInfoState
from app.core.log import logger
from app.models.es.value_info_es import ValueInfoEs
from app.models.mysql.column_info_mysql import ColumnInfoMySQL
from app.models.mysql.table_info_mysql import TableInfoMySQL
from app.models.qdrant.column_info_qdrant import ColumnInfoQdrant
from app.models.qdrant.metric_info_qdrant import MetricInfoQdrant
from app.models.qdrant import convert_column_info_from_mysql_to_qdrant


async def merge_retrieved_info(state: DataAgentState, runtime: Runtime[DataAgentContext]):
    writer = runtime.stream_writer
    writer({"stage": "合并召回信息"})
    try:
        retrieved_columns: list[ColumnInfoQdrant] = state["retrieved_columns"]
        retrieved_values: list[ValueInfoEs] = state["retrieved_values"]
        retrieved_metrics: list[MetricInfoQdrant] = state["retrieved_metrics"]
        meta_mysql_repository = runtime.context["meta_mysql_repository"]

        table_infos: list[TableInfoState] = []
        metric_infos: list[MetricInfoState] = []

        # 去重
        retrieved_columns_map: dict[str, ColumnInfoQdrant] = {
            retrieved_column["id"]: retrieved_column for retrieved_column in retrieved_columns
        }

        # 1. 补充指标关联的字段
        for retrieved_metric in retrieved_metrics:
            relevant_columns = retrieved_metric["relevant_columns"]
            for relevant_column in relevant_columns:
                if relevant_column not in retrieved_columns_map:
                    column_info_mysql: ColumnInfoMySQL = await meta_mysql_repository.get_column_info_by_id(relevant_column)
                    if column_info_mysql is None:
                        logger.warning(f"指标关联字段 '{relevant_column}' 在meta数据库中不存在，已跳过")
                        continue
                    column_info_qdrant: ColumnInfoQdrant = convert_column_info_from_mysql_to_qdrant(column_info_mysql)
                    retrieved_columns_map[relevant_column] = column_info_qdrant

        # 2. 补充字段取值对应的字段信息
        for retrieved_value in retrieved_values:
            column_id = retrieved_value["column_id"]
            column_value = retrieved_value["value"]
            if column_id not in retrieved_columns_map:
                column_info_mysql: ColumnInfoMySQL = await meta_mysql_repository.get_column_info_by_id(column_id)
                if column_info_mysql is None:
                    logger.warning(f"取值关联字段 '{column_id}' 在meta数据库中不存在，已跳过")
                    continue
                column_info_qdrant: ColumnInfoQdrant = convert_column_info_from_mysql_to_qdrant(column_info_mysql)
                retrieved_columns_map[column_id] = column_info_qdrant
            if column_value not in retrieved_columns_map[column_id]["examples"]:
                retrieved_columns_map[column_id]["examples"].append(column_value)

        # 3. 按表分组
        table_to_column_map: dict[str, list[ColumnInfoQdrant]] = {}
        for column in retrieved_columns_map.values():
            table_id = column["table_id"]
            if table_id not in table_to_column_map:
                table_to_column_map[table_id] = []
            table_to_column_map[table_id].append(column)

        # 4. 补充主外键
        for table_id in table_to_column_map.keys():
            key_columns: list[ColumnInfoMySQL] = await meta_mysql_repository.get_key_columns_by_table_id(table_id)
            column_ids = [column["id"] for column in table_to_column_map[table_id]]
            for key_column in key_columns:
                column_id = key_column.id
                if column_id not in column_ids:
                    table_to_column_map[table_id].append(convert_column_info_from_mysql_to_qdrant(key_column))

        # 5. 构建 TableInfoState
        for table_id, columns in table_to_column_map.items():
            columns_state = [
                ColumnInfoState(
                    name=column['name'], type=column['type'], role=column['role'],
                    examples=column['examples'], description=column["description"], alias=column["alias"]
                ) for column in columns
            ]
            table_info_mysql: TableInfoMySQL = await meta_mysql_repository.get_table_by_id(table_id)
            table_info = TableInfoState(
                name=table_info_mysql.name, role=table_info_mysql.role,
                description=table_info_mysql.description, columns=columns_state
            )
            table_infos.append(table_info)

        logger.info(f"合并表信息完成，表信息：{[t['name'] for t in table_infos]}")

        # 6. 处理指标信息
        for retrieved_metric in retrieved_metrics:
            metric_info_state = MetricInfoState(**retrieved_metric)
            metric_infos.append(metric_info_state)

        logger.info(f"合并指标信息完成：{[m['name'] for m in metric_infos]}")
        return {"table_infos": table_infos, "metric_infos": metric_infos}
    except Exception as e:
        logger.error(f"合并召回信息异常：{str(e)}")
        raise
