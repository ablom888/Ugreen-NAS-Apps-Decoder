#!/bin/bash
# cameramgr_serv 启动前准备脚本 (ExecStartPre)
# 职责：
#   1. 创建服务软链接
#   2. 启动 PostgreSQL 实例并创建数据库
#
# 注意：表结构由 Go 应用的 store.Init() 创建，此脚本只创建空数据库
# 参见：cameramgr_serv.sh 负责启动主程序

set -e

rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
[ ! -d /var/targets ] && mkdir /var/targets
ln -fsn "$rootfs"/sbin/cameramgr_serv /var/targets/

# PostgreSQL 配置
dbDir=$rootfs/db
port=5441
db=cameramgr

# 启动 PostgreSQL 实例并创建数据库
# 适配「Postgres数据库实例存在空口令」：调用 pg_common.sh 时设置 EnablePasswd=1 环境变量即可（与 music_serv 一致）
# 参见项目根目录：Postgres数据库实例存在空口令.md
# pg_common.sh 参数：dbPath, dbPort, dbName, [dbNew]
#   - dbNew 为空：正常启动
#
# 处理流程：
#   - 首次运行：初始化 PostgreSQL 数据目录，启动实例，创建数据库
#   - 后续运行：启动实例（如未运行），确保数据库存在
commonFile=/etc/startpre.d/pg_common.sh
if [ -x "$commonFile" ]; then
    # 使用平台公共脚本（推荐），EnablePasswd=1 启用二段密码
    EnablePasswd=1 "$commonFile" "${dbDir}" "${port}" "${db}" ""
else
    # 回退方案：使用基础脚本
    pgctl=/usr/lib/postgresql/15/bin/pg_ctl
    
    # 初始化 PostgreSQL 数据目录（如不存在）
    /etc/startpre.d/init_psql.sh "${dbDir}" "${port}"
    
    # 停止可能运行的旧实例，然后启动（ug-postgres 不包 su）
    ug-postgres --stop-mode --db-dir="${dbDir}" >/dev/null 2>&1
    su - postgres -c "$pgctl start -D ${dbDir} -s -w >/dev/null 2>&1"
    sleep 1
    
    # 创建数据库（如不存在）
    # 参数：dbPort, dbName, DataRoot, [password]
    /etc/startpre.d/init_database.sh "${port}" "${db}" "${dbDir}" ""
fi

# 应用 NAS 低内存调优参数（首次启动时 restart，后续跳过）
tuningScript="$rootfs/init.d/pg-tuning.sh"
if [ -x "$tuningScript" ]; then
    "$tuningScript" "${dbDir}" "${port}"
fi

echo "PostgreSQL 实例已启动 (port=${port}, db=${db})"
