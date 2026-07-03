#!/bin/bash
#/ugreen/init.d/ugreen.env

rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
[ ! -d /var/targets ] && mkdir /var/targets
ln -fsn $rootfs/sbin/iscsi_serv /var/targets/
