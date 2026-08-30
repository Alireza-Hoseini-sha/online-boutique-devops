#!/usr/bin/env bash

KEY="$HOME/.ssh/ansible_ed25519"

if [[ -f "$KEY" ]]; then
    echo "SSH key already exists: $KEY"
    exit 1
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

ssh-keygen -t ed25519 -f "$KEY" -C "ansible" 

chmod 600 "$KEY"
chmod 644 "$KEY.pub"

echo "Ansible SSH key generated:"
echo "Private key: $KEY"
echo "Public key:  $KEY.pub"
