terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

# 1. MongoDB Image & Container
resource "docker_image" "mongodb" {
  name         = "mongo:latest"
  keep_locally = true
}

resource "docker_container" "mongodb" {
  image = docker_image.mongodb.image_id
  name  = "mongodb"
  ports {
    internal = 27017
    external = 27017
  }
}

# 2. MinIO Image & Container
resource "docker_image" "minio" {
  name         = "quay.io/minio/minio:latest"
  keep_locally = true
}

resource "docker_container" "minio" {
  image = docker_image.minio.image_id
  name  = "minio"
  command = ["server", "/data", "--console-address", ":9001"]
  ports {
    internal = 9000
    external = 9000
  }
  ports {
    internal = 9001
    external = 9001
  }
  env = [
    "MINIO_ROOT_USER=admin",
    "MINIO_ROOT_PASSWORD=password123"
  ]
}