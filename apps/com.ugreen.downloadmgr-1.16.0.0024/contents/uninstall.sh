#!/bin/bash

##卸载应用时,先执行卸载脚本，处理卸载时需要处理的操作
"$(dirname "$(readlink -f "$0")")"/sbin/download_serv uninstall > /dev/null