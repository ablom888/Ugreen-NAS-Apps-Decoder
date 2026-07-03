#!/bin/bash
# cameramgr_serv 启动脚本 (ExecStart)
# 职责：
#   1. 定位配置文件路径
#   2. 启动 cameramgr_serv 主程序
#
# 参见：cameramgr_serv_pre.sh 负责启动前准备（PostgreSQL 等）

# 通过软链接定位真实安装路径
# /var/targets/cameramgr_serv -> /volume1/@appstore/com.ugreen.cameramgr/sbin/cameramgr_serv
rootfs=$(dirname $(dirname $(readlink -f /var/targets/cameramgr_serv)))

# 配置文件路径
configPath="$rootfs/config/config.yaml"

# 验证配置文件存在
if [ ! -f "$configPath" ]; then
    echo "ERROR: config file not found: $configPath" >&2
    exit 1
fi

# 启动主程序
# 使用 exec 替换当前进程，确保 systemd 可以正确管理进程
exec /var/targets/cameramgr_serv -config "$configPath"
