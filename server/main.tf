terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

resource "null_resource" "server_bootstrap" {
  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = "root"
    port        = 22
    private_key = file(var.ssh_key_path)
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/bootstrap.sh.tpl", {
      root_pass    = var.root_pass
      db_root_pass = var.db_root_pass
      deploy_user  = var.deploy_user
      ssh_port     = var.ssh_port
    })
    destination = "/tmp/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap.sh",
      "bash /tmp/bootstrap.sh",
      "rm -f /tmp/bootstrap.sh",
    ]
  }
}
