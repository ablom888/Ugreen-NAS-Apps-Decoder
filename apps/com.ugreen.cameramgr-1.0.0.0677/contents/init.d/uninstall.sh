#!/bin/bash
# cameramgr_serv 卸载脚本
# 职责：
#   1. 停止 PostgreSQL 实例（保留数据，便于重新安装恢复）
#   2. 清理应用图标

rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
dbDir=$rootfs/db

# 停止 PostgreSQL 实例（如果正在运行）
if [ -d "$dbDir" ]; then
    echo "停止 PostgreSQL 实例..."
    ug-postgres --stop-mode --db-dir="${dbDir}" 2>/dev/null || true
fi

# 清理应用图标
fileMgrRootfs=/ugreen/@appstore/com.ugreen.filemgr
iconType=Surveillance

if [ -x "$fileMgrRootfs/bin/clear_app_icon" ]; then
    "$fileMgrRootfs/bin/clear_app_icon" "$iconType"
fi

echo "cameramgr_serv 卸载清理完成"
