module "test-ubuntu-vm" {
  source  = "./modules/vm/ubuntu"
  ssh_key = "/root/.ssh/id_ed25519.pub"
  vm_name = "test-ubuntu"
}