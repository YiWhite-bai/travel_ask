from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
import re


_IDENTIFIER_RE = re.compile(r'^[a-zA-Z_][a-zA-Z0-9_]*$')


def _validate_identifier(name: str) -> str:
    """校验并返回安全的SQL标识符（表名/列名），防止SQL注入"""
    if not _IDENTIFIER_RE.match(name):
        raise ValueError(f"非法的SQL标识符: '{name}'")
    return name


class DwMysqlRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_column_types(self, table_name: str) -> dict[str, str]:
        table_name = _validate_identifier(table_name)
        sql = f"SHOW COLUMNS FROM `{table_name}`"
        result = await self.session.execute(text(sql))
        return {row.Field: row.Type for row in result.fetchall()}

    async def get_column_values(self, table_name: str, column_name: str, limit: int = 10) -> list[str]:
        table_name = _validate_identifier(table_name)
        column_name = _validate_identifier(column_name)
        sql = f"SELECT DISTINCT `{column_name}` FROM `{table_name}` LIMIT :limit"
        result = await self.session.execute(text(sql), {"limit": limit})
        return result.scalars().fetchall()

    async def get_db_info(self):
        result = await self.session.execute(text("SELECT VERSION()"))
        version = result.scalar()
        dialect = self.session.get_bind().dialect.name
        return {"version": version, "dialect": dialect}

    async def validate_sql(self, sql: str):
        await self.session.execute(text(f"EXPLAIN {sql}"))

    async def execute_sql(self, sql: str):
        result = await self.session.execute(text(sql))
        return [dict(row) for row in result.mappings().fetchall()]
