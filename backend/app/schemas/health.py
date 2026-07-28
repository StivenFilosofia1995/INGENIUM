from datetime import datetime

from pydantic import BaseModel


class HealthStatus(BaseModel):
    status: str
    app_env: str
    timestamp: datetime
