#!/bin/bash

rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
[ ! -d /var/targets ] && mkdir /var/targets
ln -fsn "$rootfs"/sbin/vault_serv /var/targets/
