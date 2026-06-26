import uuid
from datetime import datetime, date, timedelta
from decimal import Decimal
from pathlib import Path

from omegaconf import OmegaConf

from app.clients.embedding_client_manager import TEIEmbeddings

from app.conf.meta_config import MetaConfig
from app.core.log import logger
from app.models.es.value_info_es import ValueInfoEs
from app.models.mysql.column_info_mysql import ColumnInfoMySQL
from app.models.mysql.column_metric_mysql import ColumnMetricMySQL
from app.models.mysql.metric_info_mysql import MetricInfoMySQL
from app.models.mysql.table_info_mysql import TableInfoMySQL
from app.models.qdrant.column_info_qdrant import ColumnInfoQdrant
from app.models.qdrant.metric_info_qdrant import MetricInfoQdrant
from app.models.qdrant import convert_column_info_from_mysql_to_qdrant, convert_metric_info_from_mysql_to_qdrant
from app.models.qdrant.column_info_qdrant import ColumnInfoQdrant
from app.models.qdrant.metric_info_qdrant import MetricInfoQdrant
from app.repositories.es.values_es_repository import ValueEsRepository
from app.repositories.mysql.dw_mysql_repository import DwMysqlRepository
from app.repositories.mysql.meta_mysql_repository import MetaMysqlRepository
from app.repositories.qdrant.column_qdrant_repository import ColumnQdrantRepository
from app.repositories.qdrant.metric_qdrant_repository import MetricQdrantRepository


class MetaKnowledgeService:
    def __init__(self,
                 meta_mysql_repository: MetaMysqlRepository,
                 dw_mysql_repository: DwMysqlRepository,
                 column_qdrant_repository: ColumnQdrantRepository,
                 embeddings: TEIEmbeddings,
                 column_es_repository: ValueEsRepository,
                 metric_qdrant_repository: MetricQdrantRepository):
        self.meta_mysql_repository = meta_mysql_repository
        self.dw_mysql_repository = dw_mysql_repository
        self.column_qdrant_repository = column_qdrant_repository
        self.embeddings = embeddings
        self.column_es_repository = column_es_repository
        self.metric_qdrant_repository = metric_qdrant_repository

    async def build(self, config_path: Path):
        # 加载配置文件
        context = OmegaConf.load(config_path)
        schema = OmegaConf.structured(MetaConfig)
        meta_config: MetaConfig = OmegaConf.to_object(OmegaConf.merge(schema, context))
        logger.info("配置文件加载完成")

        # 处理表信息
        if meta_config.tables:
            column_infos: list[ColumnInfoMySQL] = await self._save_table_info_to_meta_db(meta_config)
            logger.info("保存表信息到meta数据库完成")
            await self._save_column_info_to_qdrant(column_infos)
            logger.info("为字段构建向量索引完成")
            await self._save_column_value_to_es(meta_config, column_infos)
            logger.info("为字段取值建立全文索引完成")

        # 处理指标信息
        if meta_config.metrics:
            metric_infos: list[MetricInfoMySQL] = await self.save_metric_info_to_meta_db(meta_config)
            logger.info("保存指标信息到meta数据库完成")
            await self._save_metric_info_to_qdrant(metric_infos)
            logger.info("为指标信息构建向量索引完成")

    async def _save_table_info_to_meta_db(self, meta_config: MetaConfig) -> list[ColumnInfoMySQL]:
        table_infos: list[TableInfoMySQL] = []
        column_infos: list[ColumnInfoMySQL] = []

        for table in meta_config.tables:
            table_info_mysql = TableInfoMySQL(
                id=table.name, name=table.name, role=table.role, description=table.description
            )
            table_infos.append(table_info_mysql)

            column_info_types: dict[str, str] = await self.dw_mysql_repository.get_column_types(table.name)
            for column in table.columns:
                column_info_values: list = await self.dw_mysql_repository.get_column_values(table.name, column.name)
                # 将Decimal/datetime等类型转为JSON兼容的基本类型
                safe_values = []
                for v in column_info_values:
                    if v is None:
                        safe_values.append(None)
                    elif isinstance(v, (Decimal, datetime, date, timedelta)):
                        safe_values.append(str(v))
                    else:
                        safe_values.append(v)
                column_info_mysql = ColumnInfoMySQL(
                    id=f"{table.name}.{column.name}",
                    name=column.name,
                    type=column_info_types[column.name],
                    role=column.role,
                    examples=safe_values,
                    description=column.description,
                    alias=column.alias,
                    table_id=table.name,
                )
                column_infos.append(column_info_mysql)

        async with self.meta_mysql_repository.session.begin():
            await self.meta_mysql_repository.save_table_infos(table_infos)
            await self.meta_mysql_repository.save_column_infos(column_infos)
        return column_infos

    async def _save_column_info_to_qdrant(self, column_infos: list[ColumnInfoMySQL]):
        await self.column_qdrant_repository.ensure_collection()
        points: list[dict] = []
        for column_info in column_infos:
            points.append({"id": uuid.uuid4(), "embedding_text": column_info.name,
                           "payload": convert_column_info_from_mysql_to_qdrant(column_info)})
            points.append({"id": uuid.uuid4(), "embedding_text": column_info.description,
                           "payload": convert_column_info_from_mysql_to_qdrant(column_info)})
            for alia in column_info.alias:
                points.append({"id": uuid.uuid4(), "embedding_text": alia,
                               "payload": convert_column_info_from_mysql_to_qdrant(column_info)})

        embedding_texts = [point['embedding_text'] for point in points]
        embeddings = []
        batch_size = 10
        for i in range(0, len(embedding_texts), batch_size):
            batch_embedding_texts = embedding_texts[i:i + batch_size]
            embedding = await self.embeddings.aembed_documents(batch_embedding_texts)
            embeddings.extend(embedding)

        ids = [point['id'] for point in points]
        payloads = [point['payload'] for point in points]
        await self.column_qdrant_repository.upsert_column(ids, embeddings, payloads)

    async def _save_column_value_to_es(self, meta_config: MetaConfig, column_infos: list[ColumnInfoMySQL]):
        await self.column_es_repository.ensure_index()
        column2sync: dict = {}
        for table in meta_config.tables:
            for column in table.columns:
                column2sync[f"{table.name}.{column.name}"] = column.sync

        value_infos: list[ValueInfoEs] = []
        for column_info in column_infos:
            sync = column2sync[column_info.id]
            if sync:
                column_values: list[str] = await self.dw_mysql_repository.get_column_values(
                    column_info.table_id, column_info.name, 10000
                )
                sub_value_infos: list[ValueInfoEs] = [
                    ValueInfoEs(
                        id=f"{column_info.id}.{column_value}",
                        value=column_value, type=column_info.type,
                        column_id=column_info.id, column_name=column_info.name,
                        table_id=column_info.table_id, table_name=column_info.table_id
                    ) for column_value in column_values
                ]
                value_infos.extend(sub_value_infos)
        await self.column_es_repository.save_column_values(value_infos)

    async def save_metric_info_to_meta_db(self, meta_config: MetaConfig) -> list[MetricInfoMySQL]:
        metric_infos: list[MetricInfoMySQL] = []
        column_metrics: list[ColumnMetricMySQL] = []

        for metric in meta_config.metrics:
            metric_info = MetricInfoMySQL(
                id=metric.name, name=metric.name, description=metric.description,
                relevant_columns=metric.relevant_columns, alias=metric.alias
            )
            metric_infos.append(metric_info)
            for relevant_column in metric.relevant_columns:
                column_metric = ColumnMetricMySQL(column_id=relevant_column, metric_id=metric.name)
                column_metrics.append(column_metric)

        async with self.meta_mysql_repository.session.begin():
            await self.meta_mysql_repository.save_metrics(metric_infos)
            await self.meta_mysql_repository.save_column_metrics(column_metrics)
        return metric_infos

    async def _save_metric_info_to_qdrant(self, metric_infos: list[MetricInfoMySQL]):
        await self.metric_qdrant_repository.ensure_collection()
        points: list[dict] = []
        for metric_info in metric_infos:
            points.append({"id": uuid.uuid4(), "embedding_text": metric_info.name,
                           "payload": convert_metric_info_from_mysql_to_qdrant(metric_info)})
            points.append({"id": uuid.uuid4(), "embedding_text": metric_info.description,
                           "payload": convert_metric_info_from_mysql_to_qdrant(metric_info)})
            for alia in metric_info.alias:
                points.append({"id": uuid.uuid4(), "embedding_text": alia,
                               "payload": convert_metric_info_from_mysql_to_qdrant(metric_info)})

        embedding_texts = [point['embedding_text'] for point in points]
        embeddings = []
        batch_size = 10
        for i in range(0, len(embedding_texts), batch_size):
            batch_embedding_texts = embedding_texts[i:i + batch_size]
            embedding = await self.embeddings.aembed_documents(batch_embedding_texts)
            embeddings.extend(embedding)

        ids = [point['id'] for point in points]
        payloads = [point['payload'] for point in points]
        await self.metric_qdrant_repository.upsert_metric(ids, embeddings, payloads)
