#!/bin/bash

FILE="/etc/systemd/system/ugminidlna.service"

# 首次 minidlna 迁移到 ugminidlna
if [ ! -e "$FILE" ]; then
  # 配置迁移 
  mv /etc/minidlna.conf /etc/ugminidlna.conf
  systemctl stop minidlna
  dpkg --force-all --purge minidlna
fi
