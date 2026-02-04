output "container_id" {
  description = "ID of the created container"
  value       = proxmox_virtual_environment_container.container.id
}

output "container_hostname" {
  description = "Hostname of the created container"
  value       = proxmox_virtual_environment_container.container.initialization[0].hostname
}

output "container_ip" {
  description = "IP address of the container"
  value       = try(proxmox_virtual_environment_container.container.initialization[0].ip_config[0].ipv4[0].address, "dhcp")
}

output "target_node" {
  description = "Proxmox node where the container is running"
  value       = proxmox_virtual_environment_container.container.node_name
}
