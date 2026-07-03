#!/usr/bin/env bash
#
# ugreen-localize-installer.sh — установщик русской локализации на UGREEN NAS.
#
# Запускается на ВАШЕМ компьютере (macOS/Linux). Спрашивает адрес, логин и
# пароль SSH от NAS, копирует на устройство инструменты локализации и русские
# переводы, применяет их ко всем установленным приложениям и ставит systemd-таймер,
# который переприменяет локализацию после обновлений приложений.
#
# Использование:
#   ./ugreen-localize-installer.sh                 # интерактивно спросит адрес/логин/пароль
#   ./ugreen-localize-installer.sh -H 192.168.1.50 -u admin
#   UG_PASS=secret ./ugreen-localize-installer.sh -H nas.local -u admin -p 22
#   ./ugreen-localize-installer.sh -H ... -u ... --lang ru-RU --no-timer
#
# Флаги:
#   -H, --host HOST     адрес NAS (IP или имя)
#   -u, --user USER     SSH-логин (обычно admin)
#   -p, --port PORT     SSH-порт (по умолчанию 22)
#       --pass PASS     пароль (небезопасно в истории; лучше UG_PASS или ввод по запросу)
#       --lang LANG     код локали (по умолчанию ru-RU)
#       --no-timer      не ставить systemd-таймер переприменения
#       --dry-run       показать план и выйти
#
set -euo pipefail

HOST=""; USER=""; PORT=22; PASS="${UG_PASS:-}"; LANG_CODE="ru-RU"
INSTALL_TIMER=1; DRY_RUN=0
REMOTE_DIR="/opt/ug-l10n"          # постоянное место на NAS (root)
REMOTE_STAGE="\$HOME/.ug-l10n-stage"

while [ $# -gt 0 ]; do
  case "$1" in
    -H|--host) HOST="$2"; shift 2;;
    -u|--user) USER="$2"; shift 2;;
    -p|--port) PORT="$2"; shift 2;;
    --pass)    PASS="$2"; shift 2;;
    --lang)    LANG_CODE="$2"; shift 2;;
    --no-timer) INSTALL_TIMER=0; shift;;
    --dry-run) DRY_RUN=1; shift;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "неизвестный аргумент: $1" >&2; exit 2;;
  esac
done

# --- корень репозитория (папка выше install/) ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
L10N_DIR="$REPO/localization/$LANG_CODE"
TOOLS="$REPO/tools/localization"

for f in "$TOOLS/ug_localize.py" "$TOOLS/ug_checkapp.py" "$SCRIPT_DIR/apply_all.py"; do
  [ -f "$f" ] || { echo "[ошибка] не найден $f — запускайте из репозитория" >&2; exit 1; }
done
[ -d "$L10N_DIR" ] || { echo "[ошибка] нет переводов: $L10N_DIR" >&2; exit 1; }

# --- интерактивный ввод недостающего ---
[ -n "$HOST" ] || { printf "Адрес NAS (IP/host): "; read -r HOST; }
[ -n "$USER" ] || { printf "SSH-логин: "; read -r USER; }
if [ -z "$PASS" ]; then
  printf "SSH-пароль (ввод скрыт, Enter — использовать ключ/агент): "
  stty -echo 2>/dev/null || true; read -r PASS; stty echo 2>/dev/null || true; echo
fi

echo "== План =="
echo "  NAS:        $USER@$HOST:$PORT"
echo "  Локаль:     $LANG_CODE ($(ls "$L10N_DIR" | wc -l | tr -d ' ') приложений)"
echo "  На NAS:     $REMOTE_DIR (systemd-таймер: $([ $INSTALL_TIMER = 1 ] && echo да || echo нет))"
[ "$DRY_RUN" = 1 ] && { echo "(dry-run) выход."; exit 0; }

# --- транспорт: ControlMaster, один ввод пароля ---
CTL="$(mktemp -u /tmp/ug-l10n-ctl.XXXX)"
SSH_OPTS=(-p "$PORT" -o StrictHostKeyChecking=accept-new
          -o ControlMaster=auto -o ControlPath="$CTL" -o ControlPersist=120)

SSHPASS_BIN="$(command -v sshpass || true)"
run_ssh() { ssh "${SSH_OPTS[@]}" "$USER@$HOST" "$@"; }
run_scp() { scp -P "$PORT" -o ControlPath="$CTL" -o StrictHostKeyChecking=accept-new "$@"; }

if [ -n "$PASS" ]; then
  if [ -z "$SSHPASS_BIN" ]; then
    echo "[!] задан пароль, но нет 'sshpass'." >&2
    echo "    Установите: macOS — brew install hudochenkov/sshpass/sshpass ; Debian — apt install sshpass" >&2
    echo "    Либо запустите без пароля (используются SSH-ключ/агент)." >&2
    exit 1
  fi
  run_ssh() { sshpass -p "$PASS" ssh "${SSH_OPTS[@]}" "$USER@$HOST" "$@"; }
  run_scp() { sshpass -p "$PASS" scp -P "$PORT" -o ControlPath="$CTL" -o StrictHostKeyChecking=accept-new "$@"; }
fi

echo "== Проверка соединения =="
run_ssh "echo ok; id" || { echo "[ошибка] не удалось подключиться" >&2; exit 1; }

# root или sudo?
REMOTE_UID="$(run_ssh 'id -u' | tr -d '\r')"
if [ "$REMOTE_UID" = "0" ]; then SUDO=""; else SUDO="sudo"; fi
# sudo с паролем (если не root и есть пароль)
sudo_cmd() {
  if [ -z "$SUDO" ]; then run_ssh "$@";
  elif [ -n "$PASS" ]; then run_ssh "echo '$PASS' | sudo -S -p '' bash -lc \"$*\"";
  else run_ssh "sudo bash -lc \"$*\""; fi
}

echo "== Копирование на NAS (staging) =="
run_ssh "rm -rf $REMOTE_STAGE && mkdir -p $REMOTE_STAGE/$LANG_CODE"
run_scp "$TOOLS/ug_localize.py" "$TOOLS/ug_checkapp.py" "$SCRIPT_DIR/apply_all.py" \
        "$USER@$HOST:$(run_ssh "echo $REMOTE_STAGE")/"
# переводы
run_scp -r "$L10N_DIR/." "$USER@$HOST:$(run_ssh "echo $REMOTE_STAGE")/$LANG_CODE/"
# systemd units
run_scp "$SCRIPT_DIR/systemd/ug-l10n-reapply.service" \
        "$SCRIPT_DIR/systemd/ug-l10n-reapply.timer" \
        "$USER@$HOST:$(run_ssh "echo $REMOTE_STAGE")/"

echo "== Установка в $REMOTE_DIR =="
sudo_cmd "rm -rf $REMOTE_DIR && mkdir -p $REMOTE_DIR && cp -r $REMOTE_STAGE/. $REMOTE_DIR/ && chown -R root:root $REMOTE_DIR"

echo "== Применение локализации ко всем приложениям =="
sudo_cmd "python3 $REMOTE_DIR/apply_all.py --lang $LANG_CODE"

if [ "$INSTALL_TIMER" = 1 ]; then
  echo "== Установка systemd-таймера переприменения =="
  sudo_cmd "cp $REMOTE_DIR/ug-l10n-reapply.service $REMOTE_DIR/ug-l10n-reapply.timer /etc/systemd/system/ && systemctl daemon-reload && systemctl enable --now ug-l10n-reapply.timer && systemctl status ug-l10n-reapply.timer --no-pager | head -4 || true"
fi

echo "== Уборка staging =="
run_ssh "rm -rf $REMOTE_STAGE" || true
# закрыть master-соединение
ssh -O exit -o ControlPath="$CTL" "$USER@$HOST" 2>/dev/null || true

echo
echo "✓ Готово. Русская локализация применена ко всем установленным приложениям."
echo "  Обновите страницу веб-интерфейса UGOS (Ctrl+F5) и выберите язык в настройках."
[ "$INSTALL_TIMER" = 1 ] && echo "  systemd-таймер ug-l10n-reapply переприменит переводы после обновлений приложений."
