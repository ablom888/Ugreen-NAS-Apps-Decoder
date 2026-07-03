# Установщик русской локализации для UGREEN NAS

Один скрипт: вводите адрес и логин/пароль SSH от NAS — он копирует переводы на
устройство, локализует **все установленные приложения** и ставит автообновление
локализации после апдейтов. Переподписи пакетов не требуется
(см. [../docs/SIGNING.md](../docs/SIGNING.md)).

## Требования

- На вашем компьютере: `bash`, `ssh`, `scp`. Для входа по паролю — `sshpass`
  (macOS: `brew install hudochenkov/sshpass/sshpass`; Debian/Ubuntu: `apt install sshpass`).
  Без пароля используются ваш SSH-ключ/агент.
- На NAS: включённый SSH, учётка с правами администратора (sudo) или root, Python 3.

## Запуск

Из корня репозитория (чтобы рядом были `tools/` и `localization/`):

```bash
# интерактивно спросит адрес, логин и пароль
./install/ugreen-localize-installer.sh

# или сразу с параметрами
./install/ugreen-localize-installer.sh -H 192.168.1.50 -u admin -p 22

# пароль через переменную окружения (не попадает в историю)
UG_PASS='ваш_пароль' ./install/ugreen-localize-installer.sh -H nas.local -u admin
```

Полезные флаги: `--lang ru-RU` (по умолчанию), `--no-timer` (без автообновления),
`--dry-run` (показать план и выйти).

## Что делает

1. Подключается по SSH (один ввод пароля через ControlMaster).
2. Копирует в `/opt/ug-l10n` на NAS: `ug_localize.py`, `ug_checkapp.py`,
   `apply_all.py` и переводы `ru-RU/<appId>/ru-RU.json`.
3. Запускает `apply_all.py`: для каждого установленного приложения ставит русскую
   локаль (`www/locale/ru-RU.json` + `.gz`), добавляет `ru-RU` в `languageList`,
   обновляет манифест целостности `.check-app`, перезапускает сервис.
   Приложения, которых нет на устройстве, пропускаются.
4. Ставит systemd-таймер `ug-l10n-reapply.timer` (при загрузке и раз в сутки),
   чтобы вернуть локализацию после обновления приложений (апдейт кладёт
   оригинальные файлы обратно).

## Проверка и откат

```bash
# на NAS: статус таймера и повторный прогон вручную
systemctl status ug-l10n-reapply.timer
sudo python3 /opt/ug-l10n/apply_all.py --lang ru-RU

# удалить автообновление
sudo systemctl disable --now ug-l10n-reapply.timer
sudo rm /etc/systemd/system/ug-l10n-reapply.{service,timer} && sudo systemctl daemon-reload
```

Каждое применение делает бэкап предыдущего файла локали (`<lang>.json.bak`) в папке
приложения. Ручной откат и детали — в [../docs/LOCALIZATION.md](../docs/LOCALIZATION.md).

## Безопасность

- Скрипт работает по вашему SSH и вносит изменения только в **ваши** приложения на
  **вашем** устройстве. Подпись вендора не подделывается и не обходится.
- Пароль не сохраняется; предпочтительны SSH-ключ или переменная `UG_PASS`
  вместо `--pass` (аргументы видны в списке процессов и истории).
- Изменения обратимы (бэкапы `.bak`, удаление таймера).
