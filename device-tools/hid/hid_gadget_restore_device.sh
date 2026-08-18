#!/system/bin/sh
set -eu

G=/config/usb_gadget/g1
C="$G/configs/b.1"
F="$G/functions/hid.usb0"
L="$C/f3"
STATE=/data/local/tmp/hid_gadget
UDC_FILE="$G/UDC"
UDC="$(cat "$UDC_FILE")"

[ "$(id -u)" = 0 ] || { echo "must run as root" >&2; exit 1; }
if [ -z "$UDC" ] && [ -f "$STATE/original_udc" ]; then
    UDC="$(cat "$STATE/original_udc")"
fi

rm -f "$STATE/commit"
echo "" > "$UDC_FILE" 2>/dev/null || true
rm -f "$L"
rmdir "$F" 2>/dev/null || true
[ -n "$UDC" ] && echo "$UDC" > "$UDC_FILE"
echo "[hid] restored mtp+adb"
