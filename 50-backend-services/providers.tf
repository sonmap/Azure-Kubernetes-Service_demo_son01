data "terraform_remote_state" "aks" {
  backend = "local"
  config = {
    path = "../20-aks/terraform.tfstate"
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.aks.outputs.kube_host
  client_certificate     = base64decode(data.terraform_remote_state.aks.outputs.kube_client_certificate)
  client_key             = base64decode(data.terraform_remote_state.aks.outputs.kube_client_key)
  cluster_ca_certificate = base64decode(data.terraform_remote_state.aks.outputs.kube_cluster_ca_certificate)
}
