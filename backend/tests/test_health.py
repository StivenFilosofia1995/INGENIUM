import pytest


@pytest.mark.asyncio
async def test_health_ok(client):
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert "timestamp" in body


@pytest.mark.asyncio
async def test_root_ok(client):
    response = await client.get("/")
    assert response.status_code == 200
    assert "INGENIUM TRACKER" in response.json()["message"]


@pytest.mark.asyncio
async def test_not_found_is_problem_details(client):
    response = await client.get("/api/v1/ruta-inexistente")
    assert response.status_code == 404
    assert response.headers["content-type"] == "application/problem+json"
    body = response.json()
    assert body["status"] == 404
    assert body["instance"] == "/api/v1/ruta-inexistente"
