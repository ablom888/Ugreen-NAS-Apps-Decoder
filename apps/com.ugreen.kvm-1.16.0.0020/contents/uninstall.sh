#!/bin/bash

systemctl stop libvirtd

# Delete all snapshots
for domain in $(virsh list --all --name); do
    for snapshot in $(virsh snapshot-list $domain --name); do
        virsh snapshot-delete $domain $snapshot
    done
done

# Delete all virtual machines
for domain in $(virsh list --all --name); do
    virsh destroy $domain
    virsh undefine $domain --nvram
done

# Delete all networks
for network in $(virsh net-list --all --name); do
    virsh net-destroy $network
    virsh net-undefine $network
done

# 执行golang清除程序
script_directory=$(dirname "$(realpath "$BASH_SOURCE")")
LOG_LEVEL=INFO LOG_OUTPUT=FILE USE_SYSLOG=on $script_directory/sbin/kvm_tool app uninstall --force
