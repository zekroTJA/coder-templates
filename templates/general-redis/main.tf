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

# ->> Admin parameters -----------------------------------------------------------------------------

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

# <<- Admin parameters -----------------------------------------------------------------------------

# ->> Startup parameters ---------------------------------------------------------------------------

variable "workspace_base_image" {
  description = "Which Docker base image would you like to use for your workspace?"
  default = "codercom/enterprise-base:ubuntu"
  validation {
    condition     = contains(
      ["codercom/enterprise-base:ubuntu", "codercom/code-server:latest"], 
      var.workspace_base_image)
    error_message = "Invalid Docker image!"
  }
}

variable "dotfiles_uri" {
  description = <<-EOF
  Dotfiles repo URI (optional)
  (see https://dotfiles.github.io)
  EOF
  default     = ""
}

variable "redis_enable_persistence" {
  description = "Enable Redis data persistence."
  default = false
}

# <<- Startup parameters ---------------------------------------------------------------------------

data "coder_workspace" "me" {
}

resource "docker_network" "internal_network" {
  name = "coder-internal-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
  driver = "bridge"
}

module "general" {
  source = "./modules/general"
  
  step2_arch = var.step2_arch
  step3_OS = var.step3_OS
  workspace_base_image = var.workspace_base_image
  dotfiles_uri = var.dotfiles_uri

  docker_network = docker_network.internal_network.name
}

module "redis" {
  source = "./modules/redis"
  
  enable_persistence = var.redis_enable_persistence
  
  docker_network = docker_network.internal_network.name
}