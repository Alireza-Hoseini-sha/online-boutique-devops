# VM scripts (libvirt)

Creates Ubuntu 26.04 cloud-image VMs on the default libvirt NAT network (`192.168.122.0/24`). Those guests are the inventory used by `infra/ansible`.

Run these from this directory so relative paths and the golden image filename match.

## Prerequisites

- KVM/libvirt (`virt-install`, `virsh`)
- `cloud-localds` (`sudo apt install cloud-image-utils`)
- SSH public key at `~/.ssh/id_ed25519.pub` (injected as user `devops` with passwordless sudo)

## 1. Download the golden image

```bash
cd infra/scripts
./download-golden-img.sh
```

`create-vm.sh` expects:

`infra/scripts/ubuntu-26.04-server-cloudimg-amd64.img`

`download-golden-img.sh` uses `wget` into the current working directory, so run it here (or move the `.img` next to `create-vm.sh`).

## 2. Create VMs

```bash
./create-vm.sh <name> <ram_mb> <vcpus> <disk_gb> <static_ip>
```

Example:

```bash
./create-vm.sh k8s-master 4096 2 20 192.168.122.11
```

Each VM gets:

- qcow2 disk under `/var/lib/libvirt/images/<name>/`
- static IP on `enp1s0` via cloud-init
- user `devops` with your Ed25519 key
- qemu-guest-agent

The script refuses to overwrite an existing domain or storage directory.

## 3. Create the lab in one shot

```bash
./provision-all.sh
```

| Name | RAM | vCPU | Disk | IP |
|---|---|---|---|---|
| `vm-ansible-controller` | 2 GiB | 1 | 15 GiB | 192.168.122.10 |
| `k8s-master` | 4 GiB | 2 | 20 GiB | 192.168.122.11 |
| `k8s-worker-01` | 6 GiB | 2 | 20 GiB | 192.168.122.12 |
| `k8s-worker-02` | 6 GiB | 2 | 20 GiB | 192.168.122.13 |

This only defines VMs. Kubernetes is installed with Ansible from `infra/ansible` (see that README). Wait until cloud-init finishes and SSH works before running the playbook.

## Destroy a VM

```bash
sudo virsh destroy <name>
sudo virsh undefine <name> --remove-all-storage
sudo rm -rf /var/lib/libvirt/images/<name>
```

`--remove-all-storage` may not delete a directory-backed disk layout; remove `/var/lib/libvirt/images/<name>` if it is still there before recreating.
