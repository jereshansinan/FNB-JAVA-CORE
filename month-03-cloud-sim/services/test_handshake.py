import pytest
from httpx import AsyncClient
from main import app

@pytest.mark.anyio
async def test_cloud_handshake():
    # We use AsyncClient to talk to your FastAPI app
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.get("/")
    
    assert response.status_code == 200
    data = response.json()
    
    # Verify the handshake logic we wrote
    assert data["status"] == "Cloud Simulation Online"
    assert data["database_mongodb"] == "Connected"
    assert "Connected" in data["storage_minio"]