
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

# Admin parameters

variable "step2_arch" {
  description = <<-EOF
  arch: What architecture is your Docker host on?
  note: codercom/enterprise-* images are only built for amd64
  EOF

  validation {
    condition     = contains(["amd64", "arm64", "armv7"], var.step2_arch)
    error_message = "Value must be amd64, arm64, or armv7."
  }
  sensitive = true
}

variable "step3_OS" {
  description = <<-EOF
  What operating system is your Coder host on?
  EOF

  validation {
    condition     = contains(["MacOS", "Windows", "Linux"], var.step3_OS)
    error_message = "Value must be MacOS, Windows, or Linux."
  }
  sensitive = true
}

provider "docker" {
  host = var.step3_OS == "Windows" ? "npipe:////.//pipe//docker_engine" : "unix:///var/run/docker.sock"
}

provider "coder" {
}

data "coder_workspace" "me" {
}

variable "workspace_base_image" {
  description = "Which Docker base image would you like to use for your workspace?"
  default = "codercom/enterprise-base:ubuntu"
  validation {
    condition     = contains(["codercom/enterprise-base:ubuntu", "codercom/code-server:latest"], var.workspace_base_image)
    error_message = "Invalid Docker image!"
  }
}

resource "coder_agent" "dev" {
  arch = var.step2_arch
  os   = lower(var.step3_OS)
  startup_script = var.workspace_base_image == "codercom/code-server:latest" ? "code-server --auth none" : ""
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
    dockerfile = "Dockerfile"
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
}