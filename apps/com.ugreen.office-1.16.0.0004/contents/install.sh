#!/bin/bash

#rootfs=$(dirname $(readlink -f "${BASH_SOURCE[0]}"))
rootfs=$(dirname $(readlink -f "$0"))
LOGFILE=/tmp/office_install.log

ln -fsn $rootfs/onlyoffice/documentserver /ugreen/www/ugoffice

# 安装rabbitmq
# apt-get install --reinstall -y $rootfs/rabbitmq/*.deb >> $LOGFILE 2>&1 || true
chmod 0666 /dev/null      # /dev/null如果不是0666会造成rabbitmq启动失败
#rm -rf /var/lib/rabbitmq
#dpkg --install $rootfs/rabbitmq/*.deb >> $LOGFILE 2>&1 || true

# 创建字体目录
mkdir -p $rootfs/app_data/user_fonts

# 初始换onlyoffice
cd $rootfs/onlyoffice/documentserver
mkdir -p fonts
CUSTOM_FONTS_PATH=$rootfs/app_data/user_fonts LD_LIBRARY_PATH=${PWD}/server/FileConverter/bin server/tools/allfontsgen \
  --input="${PWD}/core-fonts" \
  --allfonts-web="${PWD}/sdkjs/common/AllFonts.js" \
  --allfonts="${PWD}/server/FileConverter/bin/AllFonts.js" \
  --images="${PWD}/sdkjs/common/Images" \
  --selection="${PWD}/server/FileConverter/bin/font_selection.bin" \
  --output-web='fonts' \
  --use-system="true"

LD_LIBRARY_PATH=${PWD}/server/FileConverter/bin server/tools/allthemesgen \
  --converter-dir="${PWD}/server/FileConverter/bin"\
  --src="${PWD}/sdkjs/slide/themes"\
  --output="${PWD}/sdkjs/common/Images"
