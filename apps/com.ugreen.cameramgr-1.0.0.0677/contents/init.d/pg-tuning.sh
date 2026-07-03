#!/bin/bash
# PostgreSQL NAS 低内存调优脚本（版本化幂等）
# 通过 ALTER SYSTEM SET 写入 postgresql.auto.conf，适配低内存 NAS 场景。
#
# 用法: pg-tuning.sh <dbDir> <port>
# 可选环境变量:
#   CAMERAMGR_PG_TUNE_PROFILE=auto|extreme|balanced (默认 auto)

set -e

dbDir="$1"
port="$2"

if [ -z "$dbDir" ] || [ -z "$port" ]; then
    echo "用法: pg-tuning.sh <dbDir> <port>" >&2
    exit 1
fi

PSQL="psql -h localhost -p ${port} -U postgres -tAc"
TUNE_VERSION="v3"
STAMP_FILE="${dbDir}/.cameramgr_pg_tuning_stamp"
PROFILE="${CAMERAMGR_PG_TUNE_PROFILE:-auto}"

get_setting() {
    local key="$1"
    # Do not use psql anymore since it requires password. 
    # Just try to read from postgresql.auto.conf or return unknown
    local val=$(grep "^${key} =" "${dbDir}/postgresql.auto.conf" 2>/dev/null | cut -d"'" -f2)
    if [ -n "$val" ]; then
        echo "$val"
    else
        echo "unknown"
    fi
}

detect_rotational() {
    # 默认为 HDD，若无法检测则使用保守值
    local mount_source base rotational_file
    mount_source=$(df "${dbDir}" | awk 'NR==2 {print $1}')
    base=$(basename "${mount_source}" | sed 's/[0-9]*$//')
    rotational_file="/sys/block/${base}/queue/rotational"
    if [ -f "${rotational_file}" ]; then
        cat "${rotational_file}"
        return 0
    fi
    echo "1"
}

resolve_profile() {
    if [ "${PROFILE}" = "extreme" ] || [ "${PROFILE}" = "balanced" ]; then
        echo "${PROFILE}"
        return 0
    fi

    local mem_kb
    mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
    if [ "${mem_kb}" -gt 0 ] && [ "${mem_kb}" -le 4194304 ]; then
        echo "extreme"
    else
        echo "balanced"
    fi
}

apply_setting() {
    local key="$1"
    local val="$2"
    # 直接写入 postgresql.auto.conf 避免使用 psql 登录
    touch "${dbDir}/postgresql.auto.conf"
    if grep -q "^${key} =" "${dbDir}/postgresql.auto.conf"; then
        sed -i "s/^${key} =.*/${key} = '${val}'/" "${dbDir}/postgresql.auto.conf"
    else
        echo "${key} = '${val}'" >> "${dbDir}/postgresql.auto.conf"
    fi
}

effective_profile="$(resolve_profile)"
rotational="$(detect_rotational)"

if [ "${effective_profile}" = "extreme" ]; then
    shared_buffers="16MB"
    max_connections="14"
    effective_cache_size="64MB"
else
    shared_buffers="32MB"
    max_connections="15"
    effective_cache_size="128MB"
fi

if [ "${rotational}" = "0" ]; then
    random_page_cost="1.3"
else
    random_page_cost="2.8"
fi

desired_stamp="${TUNE_VERSION}|${effective_profile}|${shared_buffers}|${max_connections}|${random_page_cost}"
current_shared="$(get_setting shared_buffers || echo unknown)"
current_max_conn="$(get_setting max_connections || echo unknown)"
current_work_mem="$(get_setting work_mem || echo unknown)"

if [ -f "${STAMP_FILE}" ] && [ "$(cat "${STAMP_FILE}" 2>/dev/null)" = "${desired_stamp}" ] \
    && [ "${current_shared}" = "${shared_buffers}" ] \
    && [ "${current_max_conn}" = "${max_connections}" ] \
    && [ "${current_work_mem}" = "1MB" ]; then
    echo "PostgreSQL 调优参数已是目标值，跳过 (profile=${effective_profile})"
    exit 0
fi

echo "应用 PostgreSQL 低内存调优 (profile=${effective_profile}) ..."

# --- 内存参数 ---
apply_setting "shared_buffers" "${shared_buffers}"
apply_setting "work_mem" "1MB"
apply_setting "maintenance_work_mem" "16MB"
apply_setting "effective_cache_size" "${effective_cache_size}"
apply_setting "temp_buffers" "2MB"
apply_setting "wal_buffers" "1MB"
apply_setting "huge_pages" "off"
apply_setting "jit" "off"

# --- 连接数 ---
apply_setting "max_connections" "${max_connections}"

# --- Autovacuum 低内存配置 ---
apply_setting "autovacuum_work_mem" "8MB"
apply_setting "autovacuum_max_workers" "2"

# --- WAL / 检查点 ---
apply_setting "max_wal_size" "256MB"
apply_setting "min_wal_size" "32MB"
apply_setting "checkpoint_completion_target" "0.9"

# --- 并行与 I/O ---
apply_setting "max_worker_processes" "4"
apply_setting "max_parallel_workers" "2"
apply_setting "max_parallel_workers_per_gather" "1"
apply_setting "random_page_cost" "${random_page_cost}"

echo "调优参数已写入 ${dbDir}/postgresql.auto.conf，正在 restart ..."

ug-postgres --stop-mode --db-dir="${dbDir}" >/dev/null 2>&1 || true

commonFile=/etc/startpre.d/pg_common.sh
if [ -x "$commonFile" ]; then
    EnablePasswd=1 "$commonFile" "${dbDir}" "${port}" "cameramgr" ""
else
    pgctl=/usr/lib/postgresql/15/bin/pg_ctl
    su - postgres -c "$pgctl start -D ${dbDir} -s -w >/dev/null 2>&1"
fi

echo "${desired_stamp}" > "${STAMP_FILE}"
echo "PostgreSQL 低内存调优完成 (${desired_stamp})"
