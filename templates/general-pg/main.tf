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

variable "pg_username" {
  description = "The default user name for PostgreSQL."
  default = "root"
}

variable "pg_password" {
  description = "The default password for PostgreSQL."
  default = "root"
}

variable "pg_database" {
  description = "The name of the initial database for PostgreSQL."
  default = "root"
}

variable "pgadmin_email" {
  description = "The login email for PgAdmin."
  default = "root@root.com"
}

variable "pgadmin_password" {
  description = "The login password for PgAdmin."
  default = "root"
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

module "postgres" {
  source = "./modules/postgres"
  
  username = var.pg_username
  password = var.pg_password
  database = var.pg_database
  pgadmin_email = var.pgadmin_email
  pgadmin_password = var.pgadmin_password
  
  docker_network = docker_network.internal_network.name
}