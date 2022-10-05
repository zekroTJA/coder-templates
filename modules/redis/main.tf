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
variable "enable_persistence" {
  type = bool
  default = false
}

data "coder_workspace" "me" {
}

resource "docker_volume" "redis_volume" {
  name = "coder-redis-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
}

resource "docker_container" "redis" {
  name = "coder-redis-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  count = 1
  image = "redis:latest"
  hostname = "redis"
  volumes {
    container_path = "/var/redis/data"
    volume_name    = docker_volume.redis_volume.name
    read_only      = false
  }
  command = ["redis-server", "--save \"${var.enable_persistence ? "/var/redis/data" : ""}\""]
  dynamic "networks_advanced" {
    for_each = var.docker_network == "" ? [] : [1]
    content {
      name = var.docker_network
    }
  }
}