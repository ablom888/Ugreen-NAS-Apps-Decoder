#!/bin/bash

rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
[ ! -d /var/targets ] && mkdir /var/targets
ln -fsn $rootfs/sbin/antivirus_serv /var/targets/
ln -fsn $rootfs/bin/ugscan /usr/bin
ln -fsn $rootfs/bin/freshclam /usr/bin

export LD_LIBRARY_PATH=$rootfs/lib
exec /var/targets/antivirus_serv
