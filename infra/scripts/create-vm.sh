#!/usr/bin/env bash

# create-vm.sh <name> <ram_mb> <vcpus> <disk_gb> <static_ip>

set -euo pipefail

NAME="${1:?Missing VM name}"
RAM="${2:?Missing RAM}"
VCPUS="${3:?Missing vCPUs}"
DISK="${4:?Missing disk size}"
IP="${5:?Missing static IP}"

IFACE="enp1s0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="$SCRIPT_DIR/ubuntu-26.04-server-cloudimg-amd64.img"

IMG_DIR="/var/lib/libvirt/images/$NAME"
DISK_IMAGE="$IMG_DIR/disk.qcow2"
SEED_ISO="$IMG_DIR/seed.iso"

SSH_KEY="$HOME/.ssh/id_ed25519.pub"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT


# --------------------------------------------------
# Validation
# --------------------------------------------------

if [[ ! -f "$IMAGE" ]]; then
    echo "ERROR: Cloud image not found:"
    echo "  $IMAGE"
    exit 1
fi

if [[ ! -f "$SSH_KEY" ]]; then
    echo "ERROR: SSH public key not found:"
    echo "  $SSH_KEY"
    exit 1
fi

if ! command -v cloud-localds >/dev/null 2>&1; then
    echo "ERROR: cloud-localds is not installed."
    echo
    echo "Install it with:"
    echo "  sudo apt install cloud-image-utils"
    exit 1
fi

if ! command -v virt-install >/dev/null 2>&1; then
    echo "ERROR: virt-install is not installed."
    exit 1
fi


# --------------------------------------------------
# Check existing VM
# --------------------------------------------------

if sudo virsh dominfo "$NAME" >/dev/null 2>&1; then
    echo "ERROR: VM already exists: $NAME"
    echo
    echo "Check it with:"
    echo "  virsh list --all"
    echo
    echo "If you intentionally want to recreate it:"
    echo "  sudo virsh undefine $NAME"
    exit 1
fi


# --------------------------------------------------
# Check existing storage
# --------------------------------------------------

if sudo test -e "$IMG_DIR"; then
    echo "ERROR: VM storage directory already exists:"
    echo "  $IMG_DIR"
    echo
    echo "Refusing to overwrite existing VM data."
    exit 1
fi


# --------------------------------------------------
# Create storage
# --------------------------------------------------

echo "Creating VM: $NAME"

sudo mkdir -p "$IMG_DIR"

sudo cp "$IMAGE" "$DISK_IMAGE"

sudo qemu-img resize "$DISK_IMAGE" "${DISK}G"


# --------------------------------------------------
# SSH key
# --------------------------------------------------

SSH_PUBLIC_KEY="$(cat "$SSH_KEY")"


# --------------------------------------------------
# cloud-init user-data
# --------------------------------------------------

USER_DATA="$TMP_DIR/user-data.yaml"
NETWORK_CONFIG="$TMP_DIR/network-config.yaml"

cat > "$USER_DATA" <<EOF
#cloud-config

hostname: $NAME

users:
  - name: devops
    ssh-authorized-keys:
      - $SSH_PUBLIC_KEY
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

package_update: true

packages:
  - qemu-guest-agent

runcmd:
  - systemctl enable --now qemu-guest-agent
EOF


# --------------------------------------------------
# cloud-init network configuration
# --------------------------------------------------

cat > "$NETWORK_CONFIG" <<EOF
version: 2

ethernets:
  $IFACE:
    dhcp4: false
    addresses:
      - $IP/24
    routes:
      - to: default
        via: 192.168.122.1
    nameservers:
      addresses:
        - 8.8.8.8
        - 1.1.1.1
EOF


# --------------------------------------------------
# Create cloud-init seed ISO
# --------------------------------------------------

sudo cloud-localds \
    --network-config="$NETWORK_CONFIG" \
    "$SEED_ISO" \
    "$USER_DATA"


# --------------------------------------------------
# Create VM
# --------------------------------------------------

sudo virt-install \
    --name "$NAME" \
    --ram "$RAM" \
    --vcpus "$VCPUS" \
    --disk "path=$DISK_IMAGE" \
    --disk "path=$SEED_ISO,device=cdrom" \
    --network "network=default" \
    --osinfo ubuntu-lts-latest \
    --import \
    --graphics none \
    --noautoconsole

echo
echo "VM created successfully:"
echo "  Name: $NAME"
echo "  IP:   $IP"
echo "  RAM:  ${RAM}MB"
echo "  CPU:  $VCPUS"
echo "  Disk: ${DISK}GB"