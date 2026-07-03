#!/bin/bash

ROOTFS=$(dirname $(realpath "${BASH_SOURCE[0]}"))
RECORD_FILE_PATH=$ROOTFS/config/media_dir_record

uniq "$RECORD_FILE_PATH" | while IFS= read -r line; do
  setfattr -x "user.icon.type" "$line" || {
      echo "Error removing attribute from $line" >&2
      continue
  }
done

/ugreen/@appstore/com.ugreen.filemgr/bin/clear_app_icon Video

redis-cli del analysis_video_file_info stay_download_images:high stay_download_images:mid stay_download_images:low stay_download_images video:thumbnail:task ScrapeActorPlugQueue video:oe_skippter:status

redis-cli --scan --pattern "video:list:*" | xargs redis-cli del
redis-cli --scan --pattern "video:key:*" | xargs redis-cli del
redis-cli --scan --pattern "video:scraper:*" | xargs redis-cli del
