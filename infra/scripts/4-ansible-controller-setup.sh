#!/usr/bin/env bash

IP=$(virsh domifaddr vm-ansible-controller --source agent \
    | awk '/192\.168/ {print $4}' \
    | cut -d/ -f1)

if [[ -z "$IP" ]]; then
    echo "Could not determine Controller IP"
    exit 1
fi

echo "Controller IP: $IP"

# Copy Ansible SSH keys to Controller
scp -i ~/.ssh/ansible_ed25519 \
    ~/.ssh/ansible_ed25519 \
    ~/.ssh/ansible_ed25519.pub \
    ~/ssh/id_ed25519.pub
    devops@"$IP":/tmp/

# Setup Ansible Controller
ssh -i ~/.ssh/ansible_ed25519 devops@"$IP" 'bash -s' <<'EOF'

set -e

echo "Installing required packages..."

sudo apt update
sudo apt install -y \
    ansible \
    openssh-client \
    python3

echo "Installing Ansible SSH key..."

mkdir -p ~/.ssh
chmod 700 ~/.ssh

mv /tmp/ansible_ed25519 ~/.ssh/ansible_ed25519
mv /tmp/ansible_ed25519.pub ~/.ssh/ansible_ed25519.pub
mv /tmp/id_ed25519.pub ~/.ssh/id_ed25519.pub
cat ~/.ssh/id_ed25519.pub > ~/.ssh/authorized_keys
rm -rf ~/.ssh/id_ed25519.pub

chmod 600 ~/.ssh/ansible_ed25519
chmod 644 ~/.ssh/ansible_ed25519.pub

echo "Ansible Controller setup completed."

ansible --version

EOF
