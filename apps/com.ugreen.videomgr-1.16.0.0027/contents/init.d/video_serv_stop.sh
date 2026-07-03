#!/bin/bash

# 设置根目录和数据库目录
rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))
dbDir=$rootfs/db
logFile="/var/log/video_serv_stop.log"

# 记录日志并精确到毫秒
logMessage() {
    echo "$(date '+%Y-%m-%d %H:%M:%S.%3N') - $1" >> $logFile
}

# 停止PostgreSQL数据库
stopPostgres() {
    logMessage "尝试停止PostgreSQL..."
    ug-postgres --stop-mode --db-dir=${dbDir}
    if [ $? -eq 0 ]; then
        logMessage "PostgreSQL 已成功停止。"
    else
        logMessage "PostgreSQL 停止失败，继续检查进程状态。"
    fi
}

# 等待所有与videomgr相关的PostgreSQL进程退出
waitForPostgresStop() {
    retries=5
    count=0
    logMessage "检查并停止与videomgr相关的进程..."

    while [ $count -lt $retries ]; do
        if ! pgrep -f 'postgres.*videomgr' > /dev/null; then
            logMessage "所有与videomgr相关的进程已停止。"
            return 0
        else
            logMessage "检测到相关进程，尝试停止..."
            pgrep -f 'postgres.*videomgr' | xargs kill
            sleep 1
            count=$((count + 1))
        fi
    done

    logMessage "超过重试次数，仍有进程未停止。"
    return 1
}

# 脚本主要执行部分
logMessage "********************开始执行video_serv_stop.sh...****************************"
stopPostgres
waitForPostgresStop
logMessage "********************video_serv_stop.sh 执行完毕。****************************"