#!/bin/bash

rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
[ ! -d /var/targets ] && mkdir /var/targets
ln -fsn "$rootfs"/sbin/download_serv /var/targets/


export LD_LIBRARY_PATH=${rootfs}/lib
cd $rootfs
exec /var/targets/download_serv
