from app.models.mysql.column_info_mysql import ColumnInfoMySQL
from app.models.mysql.metric_info_mysql import MetricInfoMySQL
from app.models.qdrant.column_info_qdrant import ColumnInfoQdrant
from app.models.qdrant.metric_info_qdrant import MetricInfoQdrant


def convert_column_info_from_mysql_to_qdrant(column_info_mysql: ColumnInfoMySQL) -> ColumnInfoQdrant:
    """将 MySQL ORM 模型的字段信息转换为 Qdrant 中存储的字段信息 TypedDict"""
    return ColumnInfoQdrant(
        id=column_info_mysql.id, name=column_info_mysql.name, type=column_info_mysql.type,
        role=column_info_mysql.role, examples=column_info_mysql.examples,
        description=column_info_mysql.description, alias=column_info_mysql.alias,
        table_id=column_info_mysql.table_id
    )


def convert_metric_info_from_mysql_to_qdrant(metric_info_mysql: MetricInfoMySQL) -> MetricInfoQdrant:
    """将 MySQL ORM 模型的指标信息转换为 Qdrant 中存储的指标信息 TypedDict"""
    return MetricInfoQdrant(
        id=metric_info_mysql.id, name=metric_info_mysql.name, description=metric_info_mysql.description,
        relevant_columns=metric_info_mysql.relevant_columns, alias=metric_info_mysql.alias
    )
