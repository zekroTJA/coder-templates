
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

variable "step2_arch" {}
variable "step3_OS" {}
variable "workspace_base_image" {}
variable "dotfiles_uri" {}
variable "docker_network" {
  type = string
  default = ""
}

provider "docker" {
  host = var.step3_OS == "Windows" ? "npipe:////.//pipe//docker_engine" : "unix:///var/run/docker.sock"
}

data "coder_workspace" "me" {
}

resource "coder_agent" "dev" {
  arch = var.step2_arch
  os   = lower(var.step3_OS)
  startup_script = <<-EOF
  ${var.dotfiles_uri != "" ? "coder dotfiles -y ${var.dotfiles_uri}" : ""}
  ${var.workspace_base_image == "codercom/code-server:latest" ? "code-server --auth none" : ""}
  EOF
}

resource "coder_app" "code-server" {
  agent_id = var.workspace_base_image == "codercom/code-server:latest" ? coder_agent.dev.id : ""
  url      = var.workspace_base_image == "codercom/code-server:latest" ? "http://localhost:8080/?folder=/home/coder" : ""
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}-root"
}

resource "docker_image" "workspace_image" {
  name = "coder-base-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  build {
    path       = "."
    dockerfile = "./modules/general/Dockerfile"
    tag        = ["coder-base-general-workspace-image:latest"]
    build_arg = {
      BASE_IMAGE: var.workspace_base_image
    }
  }
}

resource "docker_container" "workspace" {
  count      = data.coder_workspace.me.start_count
  image      = docker_image.workspace_image.latest
  # Uses lower() to avoid Docker restriction on container names.
  name       = "coder-${data.coder_workspace.me.owner}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname   = lower(data.coder_workspace.me.name)
  dns        = ["1.1.1.1"]
  # Use the docker gateway if the access URL is 127.0.0.1
  entrypoint = ["sh", "-c", replace(coder_agent.dev.init_script, "127.0.0.1", "host.docker.internal")]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.dev.token}"]
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/home/coder/"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  volumes {
    container_path = "/var/run/docker.sock"
    host_path      = "/var/run/docker.sock"
  }
  dynamic "networks_advanced" {
    for_each = var.docker_network == "" ? [] : [1]
    content {
      name = var.docker_network
    }
  }
}