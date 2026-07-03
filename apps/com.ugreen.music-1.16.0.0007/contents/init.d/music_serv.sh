#!/bin/bash

##### 独立 db
rootfs=$(dirname $(dirname $(readlink -f "$0")))
[ ! -d /var/targets ] && mkdir /var/targets
ln -fsn $rootfs/sbin/music_serv /var/targets/

dbDir=$rootfs/db
port=5440

commonFile=/etc/startpre.d/pg_common.sh
if [ -x $commonFile ]; then
    EnablePasswd=1 /etc/startpre.d/pg_common.sh ${dbDir} ${port} "music" ""
else
    /etc/startpre.d/init_psql.sh ${dbDir} ${port}
    pgctl=/usr/lib/postgresql/15/bin/pg_ctl
    su - postgres -c "$pgctl stop -D ${dbDir} -s -w >/dev/null 2>&1;$pgctl start -D ${dbDir} -s -w >/dev/null 2>&1"
    sleep 1
    /etc/startpre.d/init_database.sh ${port} music ${dbDir}
fi

#vmtouch -ld ${dbDir} -m 100M

