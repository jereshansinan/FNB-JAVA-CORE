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

# 1. Create a Network so all containers can talk to each other
resource "docker_network" "kong_net" {
  name = "kong-net"
}

# 2. Postgres Database for Kong
resource "docker_container" "kong_db" {
  name  = "kong-database"
  image = "postgres:13"
  networks_advanced { name = docker_network.kong_net.name }
  env = [
    "POSTGRES_USER=kong",
    "POSTGRES_DB=kong",
    "POSTGRES_PASSWORD=kongpass"
  ]
  ports {
    internal = 5432
    external = 5432
  }
}

# 3. Kong Gateway
resource "docker_container" "kong_gateway" {
  name  = "kong-gateway"
  image = "kong:latest"
  networks_advanced { name = docker_network.kong_net.name }
  depends_on = [docker_container.kong_db]
  env = [
    "KONG_DATABASE=postgres",
    "KONG_PG_HOST=kong-database",
    "KONG_PG_PASSWORD=kongpass",
    "KONG_PROXY_LISTEN=0.0.0.0:8000",
    "KONG_ADMIN_LISTEN=0.0.0.0:8001"
  ]
  ports {
    internal = 8000
    external = 8000 
  }
  ports {
    internal = 8001
    external = 8001 
  }
}