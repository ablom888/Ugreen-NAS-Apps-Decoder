#!/bin/bash

rootfs=$(dirname $(readlink -f "$0"))

# 卸载rabbitmq & erlang
# apt-get purge -y $pkgs
#dpkg --purge erlang-asn1 erlang-base erlang-crypto erlang-eldap erlang-ftp erlang-inets erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key erlang-runtime-tools erlang-snmp erlang-ssl erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl rabbitmq-server socat
#rm -rf /var/lib/rabbitmq

# 停止postgresql
ugnasLocalDbPath=/usr/ugreen/local/com.ugreen.office/psql
[ ! -d ${ugnasLocalDbPath} ] && mkdir -p ${ugnasLocalDbPath}
dbpath=$ugnasLocalDbPath/db #将数据库放到emmc上，防止硬盘被唤醒
pgctl=/usr/lib/postgresql/15/bin/pg_ctl
su - postgres -c "$pgctl stop -D ${dbpath} -s -w >/dev/null 2>&1"

rm -rf ${ugnasLocalDbPath}  # 删除数据库
rm -rf /ugreen/www/ugoffice
rm -rf /tmp/ASC_CONVERT*     # 清理onlyoffice缓存的转换数据
