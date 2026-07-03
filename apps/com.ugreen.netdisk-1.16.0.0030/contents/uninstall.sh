#!/bin/bash
# 卸载脚本
set -e

rootfs=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))

# 后续如果使用postgres则取消以下注释
# 停止postgresql
#su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl stop -D $rootfs/postgres -s -w"