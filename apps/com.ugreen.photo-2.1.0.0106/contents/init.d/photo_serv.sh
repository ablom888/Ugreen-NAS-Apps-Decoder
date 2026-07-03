#!/bin/bash
rootfs=$(dirname $(dirname $(readlink -f "$0")))
[ ! -d /var/targets ] && mkdir /var/targets
ln -fsn $rootfs/sbin/photo_serv /var/targets/
dbDir=$rootfs/db
port=5434
db=photo2
pgctl=/usr/lib/postgresql/15/bin/pg_ctl

service_start() {
  db_start

  cd $rootfs/sbin
  ./photo_serv
}

service_stop() {
	local pidFile=/var/ugreen/photo_serv.pid
	if [ -e $pidFile ]; then
		kill $(cat $pidFile)
	else
		killall photo_serv
	fi
	su - postgres -c "$pgctl stop -D $dbDir -s -w >/dev/null 2>&1"
}

db_start() {
  commonFile=/etc/startpre.d/pg_common.sh
  if [ -x $commonFile ]; then
    EnablePasswd=1 /etc/startpre.d/pg_common.sh ${dbDir} ${port} ${db} ""
  else
    /etc/startpre.d/init_psql.sh ${dbDir} ${port}
    su - postgres -c "$pgctl stop -D ${dbDir} -s -w >/dev/null 2>&1;$pgctl start -D $dbDir -s -w >/dev/null 2>&1"
    sleep 1
    /etc/startpre.d/init_database.sh ${port} ${db} ${dbDir}
  fi
}

db_stop() {
   ug-postgres --stop-mode --db-dir=$dbDir
}

case $1 in
	start)
		db_start
		;;
	stop)
		db_stop
		;;
#	restart)
#		service_stop
#		sleep 1s
#		service_start
#		;;
esac
exit 0
