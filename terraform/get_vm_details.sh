#!/bin/bash
API_URL="https://100.68.123.106:8006/api2/json"
TOKEN="terraform@pve!terraform-token=9c63b78d-7304-4bf6-a97a-a215ab1e14b3"

echo "=== LXC Container 100 ==="
curl -k -s -H "Authorization: PVEAPIToken=$TOKEN" "$API_URL/nodes/pve/lxc/100/config" | jq -r '.'

echo -e "\n=== QEMU VM 102 ==="
curl -k -s -H "Authorization: PVEAPIToken=$TOKEN" "$API_URL/nodes/pve/qemu/102/config" | jq -r '.'

echo -e "\n=== QEMU VM 103 ==="
curl -k -s -H "Authorization: PVEAPIToken=$TOKEN" "$API_URL/nodes/pve/qemu/103/config" | jq -r '.'

echo -e "\n=== QEMU VM 104 ==="
curl -k -s -H "Authorization: PVEAPIToken=$TOKEN" "$API_URL/nodes/pve/qemu/104/config" | jq -r '.'
