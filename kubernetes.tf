module "kubernetes" {
  source = "git::https://github.com/alleaffengaffen/terraform-hcloud-kubernetes.git?ref=master"

  cluster_name = "cks_gugus"
  region       = "eu-central"

  default_ssh_keys      = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJov21J2pGxwKIhTNPHjEkDy90U8VJBMiAodc2svmnFC cardno:18 187 880"]
  default_ssh_port      = 59245
  default_ssh_user      = "technat"
  enable_server_backups = false
  ip_mode               = "ipv4"
  bootstrap_nodes       = true

  master_nodes = [
    {
      name        = "hawk"
      server_type = "cpx11"
      image       = "ubuntu-22.04"
      labels      = {}
      location    = "hel1"
      volumes     = []
    }
  ]

  worker_nodes = [
    {
      name        = "minion-0"
      server_type = "cx11"
      image       = "ubuntu-22.04"
      labels      = {}
      location    = "hel1"
      volumes     = []
    }
  ]

}
