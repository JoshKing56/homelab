output "container_id" {
  description = "ID of the created container"
  value       = proxmox_lxc.container.id
}

output "container_hostname" {
  description = "Hostname of the created container"
  value       = proxmox_lxc.container.hostname
}

output "container_ip" {
  description = "IP address of the container"
  value       = proxmox_lxc.container.network[0].ip
}

output "target_node" {
  description = "Proxmox node where the container is running"
  value       = proxmox_lxc.container.target_node
}
