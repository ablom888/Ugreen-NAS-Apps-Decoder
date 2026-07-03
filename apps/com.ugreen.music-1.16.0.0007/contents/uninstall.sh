#!/bin/bash

# 卸载时删除文件夹标记（通过文件管理服务脚本清理）
fileMgr_rootfs=/ugreen/@appstore/com.ugreen.filemgr
icon_type=Music

$fileMgr_rootfs/bin/clear_app_icon $icon_type