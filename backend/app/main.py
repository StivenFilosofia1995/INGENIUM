"""Punto de entrada de la API INGENIUM TRACKER."""
import logging

import structlog
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.api.v1.router import api_router
from app.core.config import get_settings

settings = get_settings()

logging.basicConfig(level=settings.log_level)
structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.add_log_level,
        structlog.processors.JSONRenderer(),
    ],
)
logger = structlog.get_logger()

app = FastAPI(
    title="INGENIUM TRACKER API",
    description=(
        "Rastreo del concepto de ingenium en literatura filosófica y técnica de acceso "
        "abierto: menciones, interpretación argumentativa, geolocalización y exportación "
        "a Obsidian."
    ),
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


def _problem_response(status_code: int, title: str, detail: str, instance: str) -> JSONResponse:
    """Construye una respuesta de error en formato problem-details (RFC 7807)."""
    return JSONResponse(
        status_code=status_code,
        media_type="application/problem+json",
        content={
            "type": "about:blank",
            "title": title,
            "status": status_code,
            "detail": detail,
            "instance": instance,
        },
    )


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    logger.warning("http_error", path=request.url.path, status=exc.status_code, detail=exc.detail)
    return _problem_response(
        exc.status_code,
        title="Error al procesar la solicitud",
        detail=str(exc.detail),
        instance=str(request.url.path),
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    logger.warning("validation_error", path=request.url.path, errors=exc.errors())
    return _problem_response(
        422,
        title="Parámetros inválidos",
        detail="Revisa los parámetros enviados: " + str(exc.errors()),
        instance=str(request.url.path),
    )


@app.get("/", tags=["health"], summary="Redirección informativa")
async def root() -> dict:
    return {"message": "INGENIUM TRACKER API — ver /docs para la documentación OpenAPI."}
