# Real-device report — OnePlus 13 (CPH2655, global, OxygenOS 15)

Field notes from actually flashing builds from this pipeline on a physical, retail
OnePlus 13 (CPH2655, global variant, stock firmware on the `EX01`/850 build,
Android 15, bootloader unlocked, Magisk-rooted). Written up here so the next
person attempting this on a real device doesn't have to rediscover it.

## This pipeline's kernel did not boot on our unit

Built `OP13-CPH-6.6.56` (the variant whose kernel version — `6.6.56` — is an
exact match for this device's shipped stock kernel) via this fork's Actions
workflow. The build itself succeeded and produced a real AnyKernel3 ZIP plus
the wireless module/firmware packs.

Two flash attempts, both failed:

1. **Naive `mkbootimg` rebuild** — bounced straight to fastboot (bad AVB
   footer).
2. **Properly repacked via `magiskboot`, preserving the real AVB footer** —
   got further, but the device rapid-power-cycled, even with vbmeta
   verification explicitly disabled. That combination (correct footer, AVB
   off, still fails) points to a genuine **KMI (kernel/vendor-module ABI)
   incompatibility** between this pipeline's kernel and the vendor modules
   already on the device — not a signing/verification problem, and not
   something a boot.img/AVB fix can work around.

We filed a repro against upstream (`Hipuu/OnePlus13-KernelBuilder#1`); at the
time, `compatibility.md` only explicitly tracked kernel `6.6.89`, not `6.6.56`,
which may be the underlying reason this specific variant doesn't work on a
global/`EX01` unit. If you're on a different regional firmware or a kernel
version upstream has explicitly validated, your mileage may genuinely differ —
this report is about the `6.6.56` global variant specifically.

**Because of this, the "Tested adapters" table in `README.md` (AR9271 —
monitor mode, injection confirmed) should not be read as "confirmed on a
CPH2655 global device" unless whoever added that row can confirm the kernel
underneath it actually booted on real retail hardware.** We could not get any
variant of this pipeline's kernel to boot on ours, so we have no data either
way on the wireless-driver loader itself.

## What actually worked instead

We pivoted to a from-scratch build directly from OnePlus's own published
source (`OnePlusOSS`'s `msm-kernel`/`common`/module-and-devicetree repos for
SM8750, via Bazel/Kleaf — not this pipeline). That approach:

- **Boots reliably.** Full stock-equivalent kernel, confirmed across many
  repeated boots.
- **Internal Wi-Fi and Bluetooth work**, once the custom kernel is paired with
  a matching custom `system_dlkm` (GKI module set). This pairing is mandatory:
  `system_dlkm`/GKI modules are locked to the *exact* kernel release string
  and signed by the kernel's own key, unlike vendor modules (`vendor_boot`/
  `vendor_dlkm`), which only need to match the KMI generation substring
  (e.g. `android15-8-o-4k`) and tolerate a stock/custom mix freely.
- **USB HID gadget (BadUSB-style keystroke injection) works out of the box**
  — no kernel patching needed, `CONFIG_USB_CONFIGFS_F_HID` is already
  built-in on this source tree. Only userspace configfs wiring was required.
- **Internal Wi-Fi packet injection is still blocked**, but the blocker is now
  narrow and understood: a from-scratch build of `cnss2.ko` (the WLAN platform
  driver, `vendor/qcom/opensource/wlan/platform/cnss2`) hard-reboots the
  device (SoC watchdog reset, no panic, nothing survives to pstore) the
  instant it's loaded. Isolated via a live `rmmod`/`insmod` swap harness
  (never by flashing whole partitions — every whole-partition swap we tried
  passed every static check and then failed identically at runtime, so static
  verification cannot catch this class of bug in this source tree). Leading
  theory: this OnePlusOSS source revision is newer than the shipped firmware
  and unconditionally probes for a "direct-link"/"FIG" hardware capability
  (`qcom,cnss-direct-link`, `qcom,cnss-fig`) this device's firmware/devicetree
  doesn't provide. Stock's own `cnss2.ko` doesn't export
  `cnss_get_direct_link_sid` at all, consistent with stock having been built
  with that feature compiled out. Actively being worked (trimming that probe
  path to match stock's feature set, or sourcing firmware-matched revision).
- Whole-partition swaps of a from-scratch-built `vendor_boot` or `vendor_dlkm`
  both froze on the OEM boot logo at runtime despite passing exhaustive static
  checks (symbol resolution, modversion CRC audits, dependency closure,
  filesystem/SELinux integrity, exact partition-size fit). Neither is required
  for the two headline NetHunter goals (wifi injection needs one module,
  cnss2/qcacld; HID needs only the kernel proper), so both are parked rather
  than pursued further.
- External adapter route: a MediaTek MT7601U build (ABI-matched to our exact
  kernel/CRCs) enumerated and initialized correctly on real hardware
  (firmware upload, PHY init all succeeded) but failed at
  `ieee80211_register_hw()` — this device's stock `mac80211` has no
  Minstrel/software rate-control algorithm registered (the Qualcomm internal
  driver uses hardware rate control instead, so the gap was invisible until
  an adapter that needs software rate control was tried). A driver-side fixed
  1 Mbps rate-control shortcut caused black-screen bootloops with the dongle
  attached and was abandoned. Recommendation for anyone hitting this: pick an
  adapter whose vendor driver does its own rate control (e.g. Realtek
  RTL8812AU / ALFA AWUS036ACH) instead of one that depends on mac80211's
  Minstrel.

## Takeaway for this repo

If you're targeting a **real retail CPH2655 global unit**, be aware this
pipeline's kernel is unconfirmed on that hardware as of this report — treat
the wireless-driver-loader claims as upstream/generic until someone confirms
a boot on this exact device+firmware combination. If your goal is internal
wifi injection or HID specifically (not an external-adapter loader), the
from-scratch OnePlusOSS source build is the path that's actually gotten a
custom kernel booting reliably on this hardware, and is worth trying instead.
