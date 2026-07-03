#!/bin/bash
rootfs="$(dirname "$(readlink -f "$0")")"
# 检查 $rootfs/bin 是否有同名的文件或者文件夹，有的话直接删除
if [ -e "$rootfs/bin" ]; then
    rm -rf "$rootfs/bin"
    echo "'bin' has been removed" | tee -a /tmp/docker-install.log
fi