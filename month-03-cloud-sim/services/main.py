from fastapi import FastAPI
from pymongo import MongoClient
import boto3

app = FastAPI()

# 1. Test MongoDB Connection (NoSQL Simulation)
mongo_client = MongoClient("mongodb://localhost:27017/")

# 2. Test MinIO Connection (S3 Simulation)
s3_client = boto3.client(
    "s3",
    endpoint_url="http://localhost:9000",
    aws_access_key_id="admin",
    aws_secret_access_key="password123"
)

@app.get("/")
def health_check():
    # Check MongoDB
    mongo_status = "Connected" if mongo_client.server_info() else "Failed"
    
    # Check MinIO
    buckets = s3_client.list_buckets()
    minio_status = f"Connected ({len(buckets['Buckets'])} buckets found)"
    
    return {
        "status": "Cloud Simulation Online",
        "database_mongodb": mongo_status,
        "storage_minio": minio_status
    }