# Overall architecture
There should only be a few VMs, each with a specific usecase
1. Prod: This should be where _stable_ and _tested_ software should be deployed to
2. Dev: This should be a copy of prod architecturally, but where software can be deployed and tested
3. Sandbox: The unstable vm. Can be nuked at a moments notice, and where things can be tested. We can rename dad-sandbox and use as the sandbox
4. Services: This is the VM we can use to host COTS services and self-hosted tools. Anything from CICD to NAS to a shared calendar
5. Services failover: This is a future feature, we can start without it
6. Batch jobs/Automation: CICD runners, cron tasks. <!-- TODO: Do we need this-->
7. Workstation/VDI machines: As Needed

# VMS
I should define the resource allocation for each vm not in static numbers, but in terms of the data and util I get from `proxmox_virtual_environment_nodes`. 
## Prod and Dev for development
OS: Debian, headless
Running: Kubernetes with Docker
Should be on separate vnets

## Sandbox
OS: This can stay as ubuntu with a UI
Schedule a complete wipe every x number of days
On it's own vnet

## Services
May have to split this into multiple vms. Unsure yet.
Probably run a kuberntes cluster with lots of different services.
OS: Debian, may be useful to run a UI. Decide this once we have a more concrete list of what we want to run

## Batch jobs
Not sure if we need this, but I was thinking if we have to do routine backup jobs, or use this VM to host CICD runners

## Workstation
UI based, 

# Setup and manage VMs
- Set up on Packer
- Provision through terraform

# Networking
- Have both internal/external facing DNS. Should be simple to switch 
- Proxmox has an SDN capability

# Services and Tools 
## DNS/Auth/SSL
- [Netbox](https://netboxlabs.com/)
- [Nginx proxy manager](https://nginxproxymanager.com/)
- [Traefik](https://doc.traefik.io/traefik/)
- Proxmox 

## Deploy
#### No-code deploy:
- [Coolify](https://coolify.io/self-hosted/)
- [Kubero](https://github.com/kubero-dev/kubero)
- [Kamal](https://kamal-deploy.org/)
#### CICD
Do the tools above take care of CICD? Need more research
- Gitlab
- Avoid Jenkins

## Artifact management
- Artifactory??? Pretty sure there's no free version. TODO research this.

## Monitoring and alerting
- Telegraf
- Influx
- Grafana
- Prometheus???

# Backup and data management
TODO lot to research here