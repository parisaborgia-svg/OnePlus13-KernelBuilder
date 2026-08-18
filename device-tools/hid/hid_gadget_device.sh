#!/system/bin/sh
set -eu

G=/config/usb_gadget/g1
C="$G/configs/b.1"
F="$G/functions/hid.usb0"
L="$C/f3"
STATE=/data/local/tmp/hid_gadget
UDC_FILE="$G/UDC"
UDC="$(cat "$UDC_FILE")"

log() { echo "[hid] $*"; }

restore() {
    log "restoring mtp+adb"
    echo "" > "$UDC_FILE" 2>/dev/null || true
    rm -f "$L"
    rmdir "$F" 2>/dev/null || true
    [ -n "$UDC" ] && echo "$UDC" > "$UDC_FILE"
}

[ "$(id -u)" = 0 ] || { echo "must run as root" >&2; exit 1; }
[ -n "$UDC" ] || { echo "g1 is not bound to a UDC" >&2; exit 1; }
[ "$(readlink "$C/f1")" = "../../../../usb_gadget/g1/functions/ffs.mtp" ] || {
    echo "unexpected f1; refusing to alter gadget" >&2; exit 1;
}
[ "$(readlink "$C/f2")" = "../../../../usb_gadget/g1/functions/ffs.adb" ] || {
    echo "unexpected f2; refusing to alter gadget" >&2; exit 1;
}

mkdir -p "$STATE"
rm -f "$STATE/commit"
printf '%s\n' "$UDC" > "$STATE/original_udc"

log "unbinding $UDC"
echo "" > "$UDC_FILE"

if [ ! -d "$F" ]; then
    mkdir "$F" || { restore; exit 1; }
fi
echo 1 > "$F/protocol" || { restore; exit 1; }
echo 1 > "$F/subclass" || { restore; exit 1; }
echo 8 > "$F/report_length" || { restore; exit 1; }

# Standard USB boot-keyboard report descriptor (8-byte reports).
base64 -d > "$F/report_desc" <<'EOF' || { restore; exit 1; }
BQEJBqEBBQcZ4CnnFQAlAXUBlQiBApUBdQiBAZUFdQEFCBkBKQWRApUBdQORAZUGdQgVACVlBQcZACllgQDA
EOF

ln -s "$F" "$L" || { restore; exit 1; }

log "binding mtp+adb+hid"
echo "$UDC" > "$UDC_FILE" || { restore; exit 1; }

# If the host cannot reconnect and create STATE/commit, restore automatically.
(
    sleep 45
    if [ ! -f "$STATE/commit" ]; then
        restore
        log "failsafe rollback completed"
    fi
) > "$STATE/failsafe.log" 2>&1 &

log "waiting for host commit (45-second failsafe armed)"
