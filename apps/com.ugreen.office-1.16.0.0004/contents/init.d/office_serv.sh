#!/bin/bash

rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
[ ! -d /var/targets ] && mkdir /var/targets
ln -fsn $rootfs/sbin/office_serv /var/targets/

ugnasLocalDbPath=/usr/ugreen/local/com.ugreen.office/psql
[ ! -d ${ugnasLocalDbPath} ] && mkdir -p ${ugnasLocalDbPath}
dbpath=$ugnasLocalDbPath/db #将数据库放到emmc上，防止硬盘被唤醒
dbport=5437
dbname=onlyoffice
dbuser=postgres
commonFile=/etc/startpre.d/pg_common.sh
pgctl=/usr/lib/postgresql/15/bin/pg_ctl
ugpostgres=/usr/sbin/ug-postgres

chmod 0666 /dev/null      # /dev/null如果不是0666会造成pgsql和rabbitmq启动失败

service_start() {
  # 先停止数据库，防止影响数据库初始化
  su - postgres -c "$pgctl stop -D ${dbpath} -s -w >/dev/null 2>&1"
  # 初始化和启动数据库
  if [ -x $commonFile ]; then
    EnablePasswd=1 /etc/startpre.d/pg_common.sh ${dbpath} ${dbport} ${dbname} ""
  else
    /etc/startpre.d/init_psql.sh ${dbpath} ${dbport}
    su - postgres -c "$pgctl start -D ${dbpath} -s -w >/dev/null 2>&1"
    sleep 1
    /etc/startpre.d/init_database.sh ${dbport} ${dbname} ${dbpath}
  fi

  # 创建数据库
  if [ -x $ugpostgres ]; then
    $ugpostgres --sql-mode --db-port=${dbport} --db-name=${dbname} --db-sql=$rootfs/onlyoffice/documentserver/server/schema/postgresql/createdb.sql
  else
    psql -h 127.0.0.1 -p $dbport -d $dbname -U $dbuser -f $rootfs/onlyoffice/documentserver/server/schema/postgresql/createdb.sql
  fi

  # 启动rabbitmq
  #systemctl enable rabbitmq-server # 开机自启动
  #systemctl restart rabbitmq-server
}

service_stop() {
  local pidFile=/var/ugreen/office_serv.pid
  if [ -e $pidFile ]; then
          kill $(cat $pidFile)
  else
          killall office_serv
  fi
  su - postgres -c "$pgctl stop -D ${dbpath} -s -w >/dev/null 2>&1"
  #systemctl disable rabbitmq-server # 禁用开机自启动
  #systemctl stop rabbitmq-server
  rm -rf /tmp/ASC_CONVERT*     # 清理onlyoffice缓存的转换数据
}

case $1 in
        start)
                service_start
                ;;
        stop)
                service_stop
                ;;
        restart)
                service_stop
                sleep 1s
                service_start
                ;;
esac
