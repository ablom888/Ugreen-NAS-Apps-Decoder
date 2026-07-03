#!/bin/bash

# 系统inode指错导致的动态链接库指向错误的旧数据修复
if ! ls -al /usr/lib/x86_64-linux-gnu/libxencall.so.1 | grep libxencall.so.1.3; then
    rm  /usr/lib/x86_64-linux-gnu/libxencall.so.1
    ln -s /usr/lib/x86_64-linux-gnu/libxencall.so.1.3   /usr/lib/x86_64-linux-gnu/libxencall.so.1
fi

# 支持 TPM 权限替换
qemu_conf="/etc/libvirt/qemu.conf"
grep -r "# TPM permission settings" $qemu_conf
# 没有替换过，进行一次替换
if [ $? -ne 0 ]; then
    echo "# TPM permission settings" >> $qemu_conf
    echo 'swtpm_user = "root"' >> $qemu_conf
    echo 'swtpm_group = "root"' >> $qemu_conf
    sync
    systemctl restart libvirtd
fi


# 每次启动的时候执行一次拉起应用操作 主要针对异常关闭的修复操作
systemctl start libvirtd

# 启动的时候默认拉起网络所有
for network in $(virsh net-list --all --name); do
    virsh net-start $network
done

# 关闭宿主机时等待虚拟机关闭逻辑调整为并行等待
sudo sed -i 's/PARALLEL_SHUTDOWN=0/PARALLEL_SHUTDOWN=10/' /usr/lib/libvirt/libvirt-guests.sh
