#!/bin/bash
# 每次更新都走覆盖安装引擎不会影响数据
# 每次安装为了解决之前系统清理了dpkg缓存信息（导致卸载不掉引擎）这样安装后缓存会再次写入

# 任何命令失败都会返回非0的状态码
# for或者if需要手动处理
set -e

if [ -f /tmp/docker-install.log ]; then
  chmod 777 /tmp/docker-install.log
fi

install_pkg() {
    local pkg="$1"
    echo "Installing dpkg package: $pkg" | tee -a /tmp/docker-install.log

    while true; do
        dpkg -i --force-all "$pkg" | tee -a /tmp/docker-install.log

        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            echo "Successfully installed: $pkg" | tee -a /tmp/docker-install.log
            break
        else
            echo "Installation failed for $pkg, retrying in 2 seconds..." | tee -a /tmp/docker-install.log
            sleep 2
        fi
    done
}

pkg_dir="$(dirname "$(readlink -f "$0")")/pkg"

for pkg in "$pkg_dir"/{docker-ce,containerd.io,docker-ce-cli,docker-compose-plugin}_*.deb; do
    [ -f "$pkg" ] && install_pkg "$pkg"
done

systemctl stop docker.socket
# 安装完成后服务启动前设置disable，不在代码中处理
systemctl disable docker
systemctl disable docker.socket

# 适配reset方案（删除根目录大于100M的文件！！！）
# 移动dockerd到安装目录
rootfs="$(dirname "$(readlink -f "$0")")"
# 检查 $rootfs/bin 是否有同名的文件或者文件夹，有的话直接删除
if [ -e "$rootfs/bin" ]; then
    rm -rf "$rootfs/bin"
    echo "'bin' has been removed" | tee -a /tmp/docker-install.log
fi

mkdir -p "$rootfs/bin"

mv /usr/bin/dockerd $rootfs/bin
# 软链dockerd到默认安装目录 （dpkg卸载会删除软链不会阻塞卸载）
ln -s $rootfs/bin/dockerd /usr/bin/dockerd

# 执行docker安装命令
"$(dirname "$(readlink -f "$0")")"/sbin/docker_serv --install | tee -a /tmp/docker-install.log

echo "install docker engine done" | tee -a /tmp/docker-install.log
