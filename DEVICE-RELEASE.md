# CPH2655 OxygenOS 15.0.0.850 device release

This repository's GitHub Actions pipeline did not boot on the retail device
described in `REAL-DEVICE-REPORT.md`. The separate GitHub prerelease assets are
from the from-scratch OnePlusOSS build that did boot repeatedly.

## Exact tested target

- Model: OnePlus 13 global, `CPH2655`
- Firmware: `CPH2655_15.0.0.850(EX01)`
- Tested slot: `_a`
- Kernel: `6.6.56-android15-8-o-gcec4a1056a32-4k`
- Bootloader: unlocked
- AVB verification: already disabled on the test phone

Do not flash these images on another model, firmware build, or kernel/KMI
generation. This is a prerelease for experienced users with a tested recovery
path, not a general-purpose ROM.

## Release assets

The two custom images are a matched set:

- `OnePlus13-CPH2655-OOS850-boot.img`
- `OnePlus13-CPH2655-OOS850-system_dlkm.img`

Keep the firmware's stock `vendor_boot` and `vendor_dlkm`. The custom versions
of those partitions failed at runtime and are deliberately not distributed.
The release also does not distribute OnePlus stock images or a patched
`init_boot` image.

Verify every file against `SHA256SUMS.txt` before flashing.

## What was verified

- Repeated successful Android boots.
- Internal Qualcomm Wi-Fi on 2.4 GHz and 5 GHz.
- Bluetooth and the expected GKI module set.
- Magisk-rooted `init_boot` remained compatible and untouched.
- USB configfs HID function, with MTP and ADB retained.
- Kali NetHunter 2026.2 Generic ARM64 Full userspace installed separately.

Internal Wi-Fi management-frame submission is documented in
`INTERNAL-WIFI-REPORT.md`; successful over-the-air injection is not yet
claimed.

## Flashing outline

Back up your own current `boot` and `system_dlkm` partitions first. Keep those
device/firmware-matched backups off the phone and confirm that you can enter
both bootloader fastboot and userspace fastbootd.

`system_dlkm` is a logical partition and must be flashed from fastbootd. Do not
boot between flashing the two members of the matched set:

```bash
sha256sum -c SHA256SUMS.txt

adb reboot fastboot
fastboot getvar is-userspace
fastboot flash system_dlkm OnePlus13-CPH2655-OOS850-system_dlkm.img
fastboot reboot bootloader
fastboot flash boot OnePlus13-CPH2655-OOS850-boot.img
fastboot reboot
```

`fastboot getvar is-userspace` must report `yes` before the `system_dlkm`
flash. After boot, confirm the exact kernel and basic hardware:

```bash
adb shell uname -r
adb shell getprop ro.build.display.id
adb shell cmd wifi status
```

Expected kernel:

```text
6.6.56-android15-8-o-gcec4a1056a32-4k
```

## Rollback

Use only backups taken from your own matching firmware. Restore
`system_dlkm` from fastbootd and `boot` from bootloader fastboot, again without
booting an unmatched pair in between:

```bash
adb reboot fastboot
fastboot flash system_dlkm YOUR_STOCK_SYSTEM_DLKM_BACKUP.img
fastboot reboot bootloader
fastboot flash boot YOUR_STOCK_BOOT_BACKUP.img
fastboot reboot
```

If Android does not boot, use the hardware key combination to reach the
bootloader, enter fastbootd, and perform the same rollback. No stock rollback
images are included because they are firmware-specific and proprietary.

## NetHunter userspace

Install Kali's official Generic ARM64 package separately. It is not mirrored
in this release. The tested archive was
`kali-nethunter-2026.2-generic-arm64-full.zip`, whose published SHA-256 was:

```text
b09756fab7939092bcf7c6242c360022426aa85b435a3285daee36a608bf8880
```

The generic package contained no kernel image and therefore left the tested
boot/system_dlkm pair intact.
