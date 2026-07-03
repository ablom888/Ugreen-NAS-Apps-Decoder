#!/bin/bash

rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))

dbDir=$rootfs/db

su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl stop -D ${dbDir} -s -w"

ps -ef | grep postgres | grep videomgr | grep -v grep | awk '{print $2}' | xargs kill
sleep 2
