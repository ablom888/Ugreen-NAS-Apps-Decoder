#!/bin/bash
rootfs=$(dirname $(dirname $(readlink -f "$0")))
[ ! -d /var/targets ] && mkdir /var/targets
ln -fsn ${rootfs}/sbin/ai_serv /var/targets/
ARCH=$(uname -m)
service_start() {
    export UGREEN_MODELS_PATH=${rootfs}/workspace
    case "$ARCH" in
        x86_64)
            export LD_LIBRARY_PATH="${rootfs}/opt/openvino/runtime/3rdparty/tbb/lib:${rootfs}/opt/openvino/runtime/lib/intel64:${rootfs}/opt/openvino_2023/runtime/lib/intel64:${rootfs}/opt/openvino_2024.1/runtime/lib/intel64:${rootfs}/usr/local/opencv4.5/lib:${rootfs}/opt/onnxruntime_1.16.1/lib:${rootfs}/lib:${rootfs}/lib/x86_64-linux-gnu:${rootfs}/opt/openssl-3.0.12/lib64:${rootfs}/opt/ImageMagick-7.1.1/lib:${rootfs}/opt/libraw-0.21.3/lib:${rootfs}/opt/onnxruntime-linux-x64-gpu-1.21.1/lib:$LD_LIBRARY_PATH"
        ;;
        *aarch64*)
            export LD_LIBRARY_PATH="${rootfs}/lib/aarch64-linux-gnu:${rootfs}/lib/opencv4.5/lib:${rootfs}/lib/openjpeg-2.4.0/lib:${rootfs}/lib/faiss/lib:${rootfs}/lib/ImageMagick-7.1.1/lib:${rootfs}/lib/OpenBLAS/lib:${rootfs}/lib/libraw-0.21.3/lib:$LD_LIBRARY_PATH"
        ;;
    esac
    export UGREEN_BLUR="${rootfs}/sbin/ai_sdk_tools/blur_ai_sdk_tool/workspace"
    export UGREEN_SCENE="${rootfs}/sbin/ai_sdk_tools/scene_ai_sdk_tool/workspace"
    export UGREEN_COMMON_OBJECT="${rootfs}/sbin/ai_sdk_tools/common_ai_sdk_tool/workspace"
    export UGREEN_CREDENTIAL="${rootfs}/sbin/ai_sdk_tools/card_ai_sdk_tool/workspace"
    export UGREEN_PET="${rootfs}/sbin/ai_sdk_tools/pet_ai_sdk_tool/workspace"
    export UGREEN_NSFW="${rootfs}/sbin/ai_sdk_tools/pron_ai_sdk_tool/workspace"
    export UGREEN_FACE="${rootfs}/sbin/ai_sdk_tools/face_ai_sdk_tool/workspace"
    export UGREEN_SIMILAR="${rootfs}/sbin/ai_sdk_tools/similar_cluster_ai_sdk_tool/workspace"
    export UGREEN_OCR="${rootfs}/sbin/ai_sdk_tools/ocr_ai_sdk_tool/workspace"
    export UGREEN_OLL="${rootfs}/sbin/ai_sdk_tools/off_line_learning_ai_sdk_tool/workspace"
    export UGREEN_ITM="${rootfs}/sbin/ai_sdk_tools/itm_image_ai_sdk_tool/workspace"
    export UGREEN_ITM_NLP="${rootfs}/sbin/ai_sdk_tools/nlp_ai_sdk_tool/workspace"
    cd $rootfs/sbin
    ./ai_serv
}

service_stop() {
	local pidFile=/var/ugreen/ai_serv.pid
	if [ -e $pidFile ]; then
		kill $(cat $pidFile)
	else
		killall ai_serv
	fi
}

case $1 in
	start)
		service_start
		;;
	stop)
		service_stop
		;;
	restart)
		service_stop
		sleep 1s
		service_start
		;;
esac
exit 0
