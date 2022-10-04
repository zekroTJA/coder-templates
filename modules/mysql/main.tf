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
variable "root_password" {
  default = "root"
}
variable "database" {
  default = "root"
}

data "coder_workspace" "me" {
}

resource "docker_volume" "mysql_volume" {
  name = "coder-mysql-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
}

resource "docker_container" "mysql" {
  name = "coder-mysql-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  count = 1
  image = "mariadb:latest"
  hostname = "mysql"
  volumes {
    container_path = "/var/lib/mysql"
    volume_name    = docker_volume.mysql_volume.name
    read_only      = false
  }
  env = [
    "MYSQL_ROOT_PASSWORD=${var.root_password}",
    "MYSQL_DATABASE=${var.database}",
  ]
  dynamic "networks_advanced" {
    for_each = var.docker_network == "" ? [] : [1]
    content {
      name = var.docker_network
    }
  }
}

resource "docker_container" "phpmyadmin" {
  name = "coder-phpmyadmin-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  count = 1
  image = "phpmyadmin/phpmyadmin:latest"
  hostname = "phpmyadmin"
  env = [
    "PMA_HOST=mysql",
    "PMA_PORT=3306",
  ]
  dynamic "networks_advanced" {
    for_each = var.docker_network == "" ? [] : [1]
    content {
      name = var.docker_network
    }
  }
}