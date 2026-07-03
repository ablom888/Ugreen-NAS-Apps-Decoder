#!/bin/bash
#
echo "start uninstall photo_serv"

rootfs=$(dirname $(readlink -f $0))
dbRoot=$rootfs/db
flagFile=$rootfs/flag_uninstall
clearAppIcon="/ugreen/@appstore/com.ugreen.filemgr/bin/clear_app_icon"
touch "$flagFile"

for i in $(ls -1 ${rootfs}/sbin/ai_sdk_tools); do
  pid=$(pgrep -f $i)
  if [ -n "$pid" ]; then
      echo "The process PID(s): $pid"
      kill -9 $pid
  fi
done

su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl stop -D $dbRoot -s -w > /dev/null 2>&1"
systemctl stop photo_serv

# uninstall the photo, delete the monitoring directory photo icon
if [ -x "$clearAppIcon" ]; then
 "$clearAppIcon" Photo > /dev/null 2>&1 || true
fi

# delete app install directory
# get directory of head of /volume from /proc/mounts and process
cat /proc/mounts | awk '{print $2}' | grep '^/volume' | while read volume_dir; do
    # log process directory
    # find and delete the directory of containing com.ugreen.photo/db
    dbDir=$volume_dir/@appstore/com.ugreen.photo/db
    echo "db dir $dbDir"
    if [ -d "$dbDir" ]; then
         rm -rf "$dbDir" 2>/dev/null
    fi
done
