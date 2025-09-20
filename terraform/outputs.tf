output "proxmox_api_url" {
  description = "The Proxmox API URL being used"
  value       = var.api_url
  sensitive   = false
}

output "proxmox_node" {
  description = "The Proxmox node being used"
  value       = var.proxmox_host
  sensitive   = false
}

output "containers" {
  description = "Information about all created containers"
  value = {
    for hostname, container in module.container : hostname => {
      id       = container.container_id
      hostname = container.container_hostname
      ip       = container.container_ip
      node     = container.target_node
    }
  }
}
