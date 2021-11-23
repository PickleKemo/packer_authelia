packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_prefix" {
  type    = string
}

variable "access" {
  type    = string
}

variable "secret" {
  type    = string
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  access_key    = "${var.access}"
  secret_key    = "${var.secret}"
  ami_name      = "${var.ami_prefix}-focal-${local.timestamp}"
  instance_type = "t3.micro"
  region        = "eu-north-1"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
  name    = "packer-build"
  sources = [
    "source.amazon-ebs.ubuntu",
  ]
  provisioner "shell" {
    inline = [
      "sudo apt update",
      "sudo apt upgrade -y",
      "sudo apt install software-properties-common",
      "sudo add-apt-repository -y ppa:ansible/ansible",
      "sudo apt update",
      "sudo apt upgrade -y",
      "sudo apt install ansible -y",
    ]
  }
  provisioner "ansible-local" {
    group_vars = "./group_vars"
    role_paths = [
      "roles/common",
      "roles/docker",
      "roles/traefik",
      "roles/authelia",
      "roles/flask",
    ]
    playbook_file = "./main.yml"    
  } 
  post-processor "manifest" {
    output = "manifest.json"
  }
  post-processor "shell-local" {
    script = "test.sh"
  }    
}
