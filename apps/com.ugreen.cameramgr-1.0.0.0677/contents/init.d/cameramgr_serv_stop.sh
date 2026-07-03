#!/bin/bash
# cameramgr_serv 停止后脚本
# 职责：
#   1. 停止 PostgreSQL 实例
#   2. 清理应用图标
#
# 注意：不使用 set -e，确保即使部分操作失败也能继续执行其他清理工作

rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
dbDir=$rootfs/db
logFile="/var/log/cameramgr_serv_stop.log"

# 记录日志
logMessage() {
    echo "$(date '+%Y-%m-%d %H:%M:%S.%3N') - $1" >> "$logFile"
}

# 停止 PostgreSQL 实例
stopPostgres() {
    logMessage "尝试停止 PostgreSQL..."
    
    if ug-postgres --stop-mode --db-dir="${dbDir}"; then
        logMessage "PostgreSQL 已成功停止"
    else
        logMessage "PostgreSQL 停止失败，检查进程状态"
        # 强制清理残留进程
        pgrep -f "postgres.*${dbDir}" | xargs -r kill 2>/dev/null || true
    fi
}

# 清理应用图标
clearAppIcon() {
    local fileMgrRootfs=/ugreen/@appstore/com.ugreen.filemgr
    local iconType=Surveillance
    
    if [ -x "$fileMgrRootfs/bin/clear_app_icon" ]; then
        "$fileMgrRootfs/bin/clear_app_icon" "$iconType"
        logMessage "应用图标已清理"
    fi
}

# 主执行
logMessage "==================== cameramgr_serv_stop.sh 开始执行 ===================="
stopPostgres
clearAppIcon
logMessage "==================== cameramgr_serv_stop.sh 执行完毕 ===================="
