#!/usr/bin/env bash
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
REMOTE=/data/local/tmp/hid_gadget

if [[ -n "${ANDROID_SERIAL:-}" ]]; then
    ADB=(adb -s "$ANDROID_SERIAL")
else
    ADB=(adb)
fi

"${ADB[@]}" get-state >/dev/null
"${ADB[@]}" shell mkdir -p "$REMOTE"
"${ADB[@]}" push "$HERE/hid_gadget_device.sh" "$REMOTE/setup.sh" >/dev/null
"${ADB[@]}" push "$HERE/hid_gadget_restore_device.sh" "$REMOTE/restore.sh" >/dev/null

setup_local=$(sha256sum "$HERE/hid_gadget_device.sh" | awk '{print $1}')
setup_remote=$("${ADB[@]}" shell sha256sum "$REMOTE/setup.sh" | awk '{print $1}')
restore_local=$(sha256sum "$HERE/hid_gadget_restore_device.sh" | awk '{print $1}')
restore_remote=$("${ADB[@]}" shell sha256sum "$REMOTE/restore.sh" | awk '{print $1}')
[[ "$setup_local" = "$setup_remote" ]] || { echo "hash verification failed for setup.sh" >&2; exit 1; }
[[ "$restore_local" = "$restore_remote" ]] || { echo "hash verification failed for restore.sh" >&2; exit 1; }

"${ADB[@]}" shell chmod 755 "$REMOTE/setup.sh" "$REMOTE/restore.sh"
echo "[host] applying HID gadget; USB will reconnect"
"${ADB[@]}" shell "su -c '$REMOTE/setup.sh'" || true

deadline=$((SECONDS + 40))
while (( SECONDS < deadline )); do
    if "${ADB[@]}" get-state >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

if ! "${ADB[@]}" get-state >/dev/null 2>&1; then
    echo "[host] ADB did not return; device failsafe will restore mtp+adb" >&2
    exit 1
fi

"${ADB[@]}" shell "su -c 'touch $REMOTE/commit'"
"${ADB[@]}" shell "su -c 'test -e /config/usb_gadget/g1/configs/b.1/f3 && test -c /dev/hidg0'"
echo "[host] committed: mtp+adb+hid active; /dev/hidg0 is ready"
