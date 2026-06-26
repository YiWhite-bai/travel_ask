from contextvars import ContextVar

# 定义异步任务上下文变量，用于在日志中追踪每个请求的唯一标识
request_id_ctx_var = ContextVar("request_id", default=1)
