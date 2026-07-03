#!/bin/bash

# 执行golang卸载清除程序
script_directory=$(dirname "$(realpath "$BASH_SOURCE")")
$script_directory/sbin/syncutils uninstall
