#!/bin/bash

rootfs=$(dirname $(dirname $(readlink -f "$0")))
[ ! -d /var/targets ] && mkdir /var/targets
ln -fsn $rootfs/sbin/video_serv /var/targets/

dbDir=$rootfs/db
port=5433

commonFile=/etc/startpre.d/pg_common.sh
if [ -x $commonFile ]; then
        EnablePasswd=1 /etc/startpre.d/pg_common.sh ${dbDir} ${port} "video" ""
else
        /etc/startpre.d/init_psql.sh ${dbDir} ${port}
        pgctl=/usr/lib/postgresql/15/bin/pg_ctl
        su - postgres -c "ug-postgres --stop-mode --db-dir=${dbDir};$pgctl start -D ${dbDir} -s -w >/dev/null 2>&1"
        sleep 1
        /etc/startpre.d/init_database.sh ${port} video ${dbDir}
fi
