import uuid
from fastapi import FastAPI, Request

from app.api.routers.query_router import query_router
from app.core.context import request_id_ctx_var
from app.core.lifespan import lifespan

# 创建FastAPI实例
app = FastAPI(lifespan=lifespan)

# 注册路由
app.include_router(query_router)


# 中间件：为每个请求生成唯一request_id
@app.middleware("http")
async def add_request_context_var(request: Request, call_next):
    request_id_ctx_var.set(uuid.uuid4())
    response = await call_next(request)
    return response
