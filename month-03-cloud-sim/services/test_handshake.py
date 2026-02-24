import pytest
from httpx import AsyncClient, ASGITransport
from main import app

@pytest.mark.anyio
async def test_cloud_handshake():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        response = await ac.get("/")
    
    assert response.status_code == 200
    data = response.json()
    
    assert data["status"] == "Cloud Simulation Online"
    assert data["database_mongodb"] == "Connected"
    assert "Connected" in data["storage_minio"]