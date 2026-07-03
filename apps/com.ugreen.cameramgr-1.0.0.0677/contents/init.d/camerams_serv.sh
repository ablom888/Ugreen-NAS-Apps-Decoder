#!/bin/bash
# camerams_serv 启动前准备脚本 (ExecStartPre)
# 职责：创建 stream_serv 软链接
# 注意：stream_serv 二进制文件已在构建时打包到 rootfs/sbin/，无需解压

set -e

rootfs=$(dirname $(dirname $(readlink -f "${BASH_SOURCE[0]}")))

# 确保 /var/targets 目录存在
[ ! -d /var/targets ] && mkdir /var/targets

# 创建软链接：/var/targets/stream_serv -> $rootfs/sbin/stream_serv
ln -fsn "$rootfs"/sbin/stream_serv /var/targets/

# 启动服务
/var/targets/stream_serv  -conf "$rootfs"/config/stream_serv.toml