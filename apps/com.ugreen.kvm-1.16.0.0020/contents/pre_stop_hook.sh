#!/bin/bash

# 禁用时需要关闭虚拟机

output=$(virsh list --name | wc -l)
# 没有虚拟机要关闭，直接退出
if [ "$output" -eq 1 ]; then
    exit
fi

# 关闭虚拟机
for domain in $(virsh list --name); do
    virsh shutdown $domain
done

# 休眠等待虚拟机关机
sleep 20

# 关机超时执行断电
for domain in $(virsh list --name); do
    virsh destroy $domain
done
