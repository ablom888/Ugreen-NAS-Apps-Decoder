#!/bin/bash
#
set -e
echo "start update photos"

rootfs=$(dirname $(readlink -f $0))

#dbRoot="$rootfs/db"
#port=5434
flagDir=$rootfs/.conf_flag
flagAiDefaultSwitchFile=$flagDir/.flag_ai_model_default_switch

# 检查目录是否存在
if [ ! -d "$flagDir" ]; then
  mkdir -p "$flagDir"
fi

touch "$flagAiDefaultSwitchFile"

# cp -rf $rootfs/opt/* /opt/
# cp -rf $rootfs/usr/local/* /usr/local/

#cp -rf $rootfs/lib/* /usr/lib/
# tar -cf - -C $rootfs/lib/ . | tar -xf - -C /usr/lib/
# cp -a $rootfs/usr/local/opencv4.5/lib/libopencv_features2d.so.4.5 /usr/lib/

 # 启动数据库
#/etc/startpre.d/init_psql.sh ${dbRoot} ${port}
# 修改目录权限
#find ${dbRoot} -type d | xargs -n 50 chmod 750
# 修改文件权限
#find ${dbRoot} -type f | xargs -n 50 chmod 750
# 修改目录宿主
#find ${dbRoot} -type d | xargs -n 50 chown postgres:postgres
# 修改文件宿主
#find ${dbRoot} -type f | xargs -n 50 chown postgres:postgres

#db_pid=$(pgrep -f $dbRoot)
#if [ -z "$db_pid" ]; then
#     其他存储空间可能安装了相册数据库(可能是卸载残留)，如果有且在运行，停止该数据库运行
#     启动当前安装目录的数据库
#      pid=$(pgrep -f com.ugreen.photo/db)
#      if [ -n "$pid" ]; then
#          echo "The process PID(s): $pid"
#          kill -9 $pid  >/dev/null 2>&1
#      fi
#      echo "start sql..."
#      su - postgres -c "/usr/lib/postgresql/15/bin/pg_ctl start -D $dbRoot -s -w" > /dev/null 2>&1
#      echo "sql started..."
#fi
#/etc/startpre.d/init_database.sh ${port} photo
exit 0