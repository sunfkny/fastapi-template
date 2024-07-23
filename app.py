import time

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger
from starlette.responses import RedirectResponse

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=True,
)


@app.middleware("http")
async def access_log(request: Request, call_next):
    start_time = time.perf_counter()
    try:
        response: Response = await call_next(request)
    except Exception as e:
        logger.exception(e)
        response = Response("Internal Server Error", status_code=500)

    process_time_ms = (time.perf_counter() - start_time) * 1000
    ip = request.client.host if request.client else "127.0.0.1"
    version = request.scope["http_version"]
    full_path = f"{request.url.path}?{request.url.query}" if request.url.query else request.url.path
    status_code = response.status_code
    method = request.method
    logger.info(f"{ip} (HTTP/{version} {status_code}) {method} {full_path} in {process_time_ms:.2f} ms")
    return response


@app.get("/")
def index():
    return RedirectResponse("/docs")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "__main__:app",
        port=8000,
        host="127.0.0.1",
        access_log=False,
    )
