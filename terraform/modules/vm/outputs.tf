output "vm_id" {
  description = "ID of the created VM"
  value       = proxmox_vm_qemu.vm.id
}

output "vm_name" {
  description = "Name of the VM"
  value       = proxmox_vm_qemu.vm.name
}

output "vm_ipv4_addresses" {
  description = "IPv4 addresses of the VM (requires qemu-guest-agent)"
  value       = proxmox_vm_qemu.vm.ipconfig0
}
