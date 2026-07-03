#!/bin/bash

# 任何命令失败都会返回非0的状态码
# for或者if需要手动处理
set -e

if [ -f /tmp/docker-uninstall.log ]; then
  chmod 777 /tmp/docker-uninstall.log
fi

echo "start uninstall docker engine" | tee -a /tmp/docker-uninstall.log

systemctl stop docker_serv
systemctl stop docker.socket

# 定义要卸载的软件包列表
#packages=(
#    "docker-compose-plugin"
#    # "docker-ce-rootless-extras"
#    "docker-ce"
#    "docker-ce-cli"
#    # "docker-buildx-plugin"
#    "containerd.io"
#)

uninstall_pkg() {
  echo "Uninstall dpkg package: $1" | tee -a /tmp/docker-uninstall.log
  local pkg="$1"
  local retry_delay=1

  while true; do
    dpkg --force-all --purge "$pkg" 2>>/tmp/docker-uninstall-error.log | tee -a /tmp/docker-uninstall.log

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
      break
    else
      echo "Failed to uninstall $pkg. Retrying in $retry_delay seconds..." | tee -a /tmp/docker-uninstall.log
      sleep $retry_delay
    fi
  done
  echo "Completed the uninstallation of dpkg package: $pkg" | tee -a /tmp/docker-uninstall.log
}

# 卸载给定包
# --purge直接用这个需要卸载顺序正确，依赖未卸载会报错
uninstall_pkg "docker-ce"
uninstall_pkg "containerd.io"
uninstall_pkg "docker-ce-cli"
uninstall_pkg "docker-compose-plugin"

# 查找Docker目录
dockerDir=`cat /etc/docker/daemon.json | sed 's/,/\n/g' | grep "data-root" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g' | sed 's/\"//g'`
if [ -z "$dockerDir" ]
then
echo "docker dir is empty"
else
echo "docker dir is $dockerDir, removing" | tee -a /tmp/docker-uninstall.log
rm -rf $dockerDir | tee -a /tmp/docker-uninstall.log
fi

# 移除引擎配置
rm /etc/docker/daemon.json

# 移除私有仓库配置
[ -f /root/.docker/config.json ] && rm /root/.docker/config.json

# 移除docker共享目录的图标
APP_NAME="Docker"
CLEAR_ICON_CMD="/ugreen/@appstore/com.ugreen.filemgr/bin/clear_app_icon"

# 检查文件是否存在
if [ -x "$CLEAR_ICON_CMD" ]; then
    "$CLEAR_ICON_CMD" "$APP_NAME"
    echo "icon cleanup completed: $CLEAR_ICON_CMD" "$APP_NAME"
else
    echo "clear_app_icon not found or not executable: $CLEAR_ICON_CMD"
fi

# 移除docker 网卡
#   读取$docker_app_dir/docker-network.log文件
#   文件中的每一行为一个12位网卡ID
#   docker创建的网卡会以br-ID组成
docker_app_dir=$(dirname "$0")
echo "start delete docker network" | tee -a /tmp/docker-uninstall.log
if [[ -f "$docker_app_dir/docker-network.log" ]]; then
    while IFS= read -r id; do
      echo "ip link delete br-$id" | tee -a /tmp/docker-uninstall.log
        ip link delete br-$id | tee -a /tmp/docker-uninstall.log
    done < "$docker_app_dir/docker-network.log"
else
    echo "not found $docker_app_dir/docker-network.log !" | tee -a /tmp/docker-uninstall.log
fi
echo "ip link delete docker0" | tee -a /tmp/docker-uninstall.log
ip link delete docker0 | tee -a /tmp/docker-uninstall.log

echo "uninstall docker engine done" | tee -a /tmp/docker-uninstall.log
