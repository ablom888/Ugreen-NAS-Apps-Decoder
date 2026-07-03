#!/bin/bash

##卸载应用时,先执行卸载脚本，处理卸载时需要处理的操作
#使用comic_serv volumes命令获取所有卷路径，并删除其中的@comic目录

# 获取当前脚本所在目录
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# 使用comic_serv volumes命令获取所有卷路径
if [ -f "$SCRIPT_DIR/sbin/comic_serv" ]; then
    # 执行命令并捕获输出和退出码
    output=$("$SCRIPT_DIR/sbin/comic_serv" clean 2>&1)
    exit_code=$?
    # 检查comic_serv命令是否执行成功
    if [ $exit_code -eq 0 ]; then
        # 成功执行，退出
        echo "comic_serv clean success !"
        exit 0
    fi
fi
