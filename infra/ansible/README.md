# Kubernetes Ansible (kubeadm)

Provisions a single-control-plane Kubernetes cluster with kubeadm, containerd, and Calico on the libvirt VMs created under `infra/scripts`.

## Layout

```
ansible/
├── ansible.cfg
├── inventory/hosts.ini
├── group_vars/all.yaml
├── playbooks/site.yaml
└── roles/
    ├── common/          # swap, sysctl, containerd, kubelet, kubeadm
    ├── control_plane/   # kubeadm init, kubectl, Calico
    └── worker/          # kubeadm join
```

Run everything from this directory so `ansible.cfg` (inventory, `roles_path`, SSH key) applies.

## Prerequisites

- Ansible on the machine that SSH into the nodes (laptop or `vm-ansible-controller`)
- SSH as `devops` with `~/.ssh/id_ed25519` (matches cloud-init in `create-vm.sh`)
- Nodes reachable at the IPs in `inventory/hosts.ini`
- First SSH to each host once if `host_key_checking` is `True`, so host keys are in `known_hosts`

## Cluster settings

Defined in `group_vars/all.yaml`:

| Variable | Value | Notes |
|---|---|---|
| `kubernetes_version` | `1.37` | pkgs.k8s.io minor repo (`v1.37`) |
| `calico_version` | `v3.28.0` | Tigera operator + custom resources |
| `pod_network_cidr` | `10.244.0.0/16` | See below |
| `cluster_user` | `devops` | kubeconfig owner on the control plane |

Calico’s default pod CIDR is `192.168.0.0/16`. That overlaps libvirt’s default NAT network (`192.168.122.0/24`). The playbooks patch Calico’s Installation to `10.244.0.0/16` so pod routes do not collide with VM IPs.

## Run

```bash
cd infra/ansible
ansible-playbook playbooks/site.yaml
```

`site.yaml` order:

1. `common` on all nodes
2. `kubeadm init` + Calico on `master`
3. `kubeadm join` on `workers`
4. `kubectl wait` until every node is `Ready` (up to 5 minutes)

Re-running the playbook is safe: init and join are skipped when kubeadm config already exists; Calico uses `kubectl apply`.

## Inventory

```ini
[master]
k8s-master ansible_host=192.168.122.11

[workers]
k8s-worker-01 ansible_host=192.168.122.12
k8s-worker-02 ansible_host=192.168.122.13
```

After a successful run, on the control plane:

```bash
ssh devops@192.168.122.11
kubectl get nodes
```
