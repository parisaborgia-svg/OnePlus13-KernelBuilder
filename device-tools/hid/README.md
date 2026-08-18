# USB HID gadget helper

These scripts add a standard boot-keyboard HID function to the tested phone's
existing MTP+ADB USB gadget. They do not send keystrokes.

Requirements:

- Rooted CPH2655 with the release kernel.
- The default `g1` gadget with `f1` = MTP and `f2` = ADB.
- ADB available on the host.

Run from the host:

```bash
./test_hid_gadget.sh
```

Set `ANDROID_SERIAL` when more than one ADB device is connected. The device
script validates the existing gadget links before changing anything and arms
a 45-second rollback. If ADB returns, the host script commits the new gadget.

Restore MTP+ADB manually:

```bash
adb shell "su -c '/data/local/tmp/hid_gadget/restore.sh'"
```

Only use HID functionality on systems you own or are explicitly authorized to
test.
