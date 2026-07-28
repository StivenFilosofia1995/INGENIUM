from datetime import UTC, datetime

from fastapi import APIRouter

from app.core.config import get_settings
from app.schemas.health import HealthStatus

router = APIRouter()


@router.get("/health", response_model=HealthStatus, summary="Estado de salud de la API")
async def health() -> HealthStatus:
    """Endpoint trivial de verificación de vida, usado por Railway/CI/monitoring."""
    settings = get_settings()
    return HealthStatus(
        status="ok",
        app_env=settings.app_env,
        timestamp=datetime.now(UTC),
    )
