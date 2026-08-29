#!/usr/bin/env bash
./create-vm.sh vm-ansible-controller 2048 1 15 192.168.122.10
./create-vm.sh k8s-master            4096 2 20 192.168.122.11
./create-vm.sh k8s-worker-01         6144 2 20 192.168.122.12
./create-vm.sh k8s-worker-02         6144 2 20 192.168.122.13