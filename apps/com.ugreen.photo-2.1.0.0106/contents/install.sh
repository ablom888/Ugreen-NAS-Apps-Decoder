#!/bin/bash
#
echo "start install photos"
rootfs=$(dirname $(readlink -f $0))
dbRoot="$rootfs/db"

#pid=$(pgrep -f com.ugreen.photo/db)
#if [ -n "$pid" ]; then
#    echo "The process PID(s): $pid"
#    kill -9 $pid >/dev/null 2>&1
#fi
su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl stop -D $dbRoot -s -w >/dev/null 2>&1"

flagFile=$rootfs/flag_uninstall
if [ -e "$flagFile" ]; then
  if [ -e "$dbRoot" ];then
    if [ -d  "$dbRoot" ]; then
        # 先备份
        dbBak="$rootfs/dbbak"
        if [ -d "$dbBak" ]; then
          rm -rf "$dbBak"
        fi
        # 备份
        mv "$dbRoot" "$dbBak"
    fi
  fi
  rm -rf "$flagFile"
fi
