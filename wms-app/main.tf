terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

resource "null_resource" "app_deploy" {
  triggers = {
    deploy_version = var.deploy_version
  }

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.deploy_user
    port        = var.ssh_port
    private_key = file(var.ssh_key_path)
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/config.php.tpl", {
      app_base_url     = var.app_base_url
      db_root_pass     = var.db_root_pass
      db_name          = var.db_name
      db_name2         = var.db_name2
      node_port        = var.node_port
      node_emit_secret = var.node_emit_secret
      server_ip        = var.server_ip
    })
    destination = "/tmp/app_config.php"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/nginx.conf.tpl", {
      app_path = var.app_path
    })
    destination = "/tmp/app_nginx.conf"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/nodejs.env.tpl", {
      node_port        = var.node_port
      node_emit_secret = var.node_emit_secret
      app_base_url     = var.app_base_url
    })
    destination = "/tmp/app_nodejs.env"
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/deploy.sh.tpl", {
      app_root     = var.app_root
      github_token = var.github_token
      github_user  = var.github_user
      github_repo  = var.github_repo
      db_name      = var.db_name
      db_name2     = var.db_name2
      app_name     = var.app_name
      node_port    = var.node_port
    })
    destination = "/tmp/deploy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/deploy.sh",
      "sudo bash /tmp/deploy.sh",
      "rm -f /tmp/deploy.sh",
    ]
  }
}
