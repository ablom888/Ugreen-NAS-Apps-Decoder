#!/bin/bash


rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
# [ ! -d /var/targets ] && mkdir /var/targets
ln -fsn $rootfs/sbin/video_serv /var/targets/

dbDir=$rootfs/db
port=5433

setDbListenAddr() {
  echo "setDbListenAddr start"
  configFile="${dbDir}/postgresql.conf"
  grep -rn "listen_addresses='127.0.0.1'" "$configFile" > /dev/null
  if [ $? -ne 0 ]; then
    echo "set db listen address"
    grep -rn $port "$configFile" > /dev/null
    if [ $? -ne 0 ]; then
      echo "listen_addresses='127.0.0.1'" >> $configFile
      echo "port=$port" >> $configFile
    else
      echo "insert listen before port"
      sed -i "/port=$port/ i\listen_addresses='127.0.0.1'" $configFile
    fi
  fi
}

ps -ef | grep postgres | grep videomgr | grep -v grep | awk '{print $2}' | xargs kill
sleep 2
psqlMasterPid=${dbDir}/postmaster.pid
if [ -e "$psqlMasterPid" ] || [ -L "$psqlMasterPid" ] || [ -S "$psqlMasterPid" ];then
  rm -rf "$psqlMasterPid"
fi
setDbListenAddr
/etc/startpre.d/init_psql.sh ${dbDir} ${port}

permission=$(stat -c %a ${dbDir})

chmod 0700 -R $dbDir > /dev/null 2>&1 && chown postgres:postgres -R $dbDir > /dev/null 2>&1

su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl start -D $dbDir -s -w"

/etc/startpre.d/init_database.sh ${port} video ${dbDir}


