#!/bin/bash

rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
[ ! -d /var/targets ] && mkdir /var/targets
ln -fsn $rootfs/sbin/cloud_serv /var/targets/

# 后续如果使用postgres则取消以下注释
# 启动postgresql
#su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl restart -D $rootfs/postgres -s -w"