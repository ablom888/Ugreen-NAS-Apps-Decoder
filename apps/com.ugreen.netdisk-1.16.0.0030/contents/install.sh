#!/bin/bash
# 安装脚本
set -e

rootfs=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))

# 后续如果使用postgres则取消以下注释
# 初始化postgresql
#dbpath=$rootfs/postgres
#dbport=5438
#dbname=netdisk
#dbuser=postgres
#mkdir -p $dbpath
#/etc/startpre.d/init_psql.sh $dbpath $dbport
#su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl start -D $dbpath -s -w"
#/etc/startpre.d/init_database.sh $dbport $dbname
#su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl stop -D $dbpath -s -w"
