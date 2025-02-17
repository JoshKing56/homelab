provider "proxmox" {
    endpoint = var.virtual_environment_endpoint
    username = var.virtual_environment_username
    password = var.virtual_environment_password

    # because self-signed TLS certificate is in use
    insecure = true

    ssh { 
        agent = true
    }
}