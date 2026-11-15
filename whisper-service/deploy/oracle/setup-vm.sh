#!/usr/bin/env bash
# One-time setup on a fresh Oracle Cloud Ubuntu VM (22.04/24.04, ARM or x86).
# Run ON THE VM:  bash setup-vm.sh
set -euo pipefail

echo "→ installing Docker"
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | sudo sh
fi
sudo usermod -aG docker "$USER"

# Oracle's Ubuntu images ship an iptables REJECT-all rule, so opening the
# ports in the VCN security list alone is not enough.
echo "→ opening ports 80/443 in the VM firewall"
sudo iptables -C INPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW -j ACCEPT 2>/dev/null \
  || sudo iptables -I INPUT 1 -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW -j ACCEPT
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent >/dev/null
sudo netfilter-persistent save

echo "✓ VM ready. Log out and back in (docker group), then run deploy.sh from your Mac."
