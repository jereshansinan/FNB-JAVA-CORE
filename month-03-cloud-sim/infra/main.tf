terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_network" "kong_net" {
  name = "kong-net"
}

# 1. THE VAULT (Database for Bank Data)
resource "docker_container" "mongodb" {
  name  = "mongodb"
  image = "mongo:latest"
  ports {
    internal = 27017
    external = 27017
  }
}

# 2. THE FILING CABINET (Storage for Documents)
resource "docker_container" "minio" {
  name  = "minio"
  image = "quay.io/minio/minio:latest"
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

# 3. KONG DATABASE (Security Settings Storage)
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

# 4. KONG GATEWAY (The Security Guard + UI)
resource "docker_container" "kong_gateway" {
  name  = "kong-gateway"
  image = "kong:latest" 
  
  networks_advanced { name = docker_network.kong_net.name }
  depends_on = [docker_container.kong_db]

  volumes {
    host_path      = "${abspath(path.module)}/kong.yml"
    container_path = "/usr/local/kong/declarative/kong.yml"
  }
  
  env = [
    "KONG_DATABASE=off",
    "KONG_DECLARATIVE_CONFIG=/usr/local/kong/declarative/kong.yml",
    "KONG_PG_HOST=kong-database",
    "KONG_PG_PASSWORD=kongpass",
    "KONG_PROXY_LISTEN=0.0.0.0:8000",
    "KONG_ADMIN_LISTEN=0.0.0.0:8001",
    "KONG_ADMIN_GUI_LISTEN=0.0.0.0:8002",
    # This turns on the Manager for the OSS version
    "KONG_ADMIN_GUI_URL=http://localhost:8002",
    "KONG_ADMIN_API_URI=http://localhost:8001"
  ]
  ports {
     internal = 8000
     external = 8000 
     }
  ports { 
    internal = 8001
    external = 8001 
  }
  ports { 
    internal = 8002 
    external = 8002 
    }
}