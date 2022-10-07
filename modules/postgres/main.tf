terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.4.2"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.16.0"
    }
  }
}

variable "docker_network" {
  default = ""
}
variable "username" {
  default = "root"
}
variable "password" {
  default = "root"
}
variable "database" {
  default = "root"
}
variable "pgadmin_email" {
  default = "root@root.com"
}
variable "pgadmin_password" {
  default = "root"
}

data "coder_workspace" "me" {
}

resource "docker_volume" "postgres_volume" {
  name = "coder-postgres-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
}

resource "docker_container" "postgres" {
  name = "coder-postgres-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  count = 1
  image = "postgres:latest"
  hostname = "postgres"
  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name    = docker_volume.postgres_volume.name
    read_only      = false
  }
  env = [
    "POSTGRES_USER=${var.username}",
    "POSTGRES_PASSWORD=${var.password}",
    "POSTGRES_DB=${var.database}"
  ]
  dynamic "networks_advanced" {
    for_each = var.docker_network == "" ? [] : [1]
    content {
      name = var.docker_network
    }
  }
}

resource "docker_container" "pgadmin" {
  name = "coder-pgadmin-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  count = 1
  image = "dpage/pgadmin4:latest"
  hostname = "pgadmin"
  env = [
    "PGADMIN_DEFAULT_EMAIL=${var.pgadmin_email}",
    "PGADMIN_DEFAULT_PASSWORD=${var.pgadmin_password}",
  ]
  dynamic "networks_advanced" {
    for_each = var.docker_network == "" ? [] : [1]
    content {
      name = var.docker_network
    }
  }
}