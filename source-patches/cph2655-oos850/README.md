# Corresponding source notes

The device prerelease was built from OnePlusOSS SM8750 sources at these base
commits:

| Repository | Base commit |
|---|---|
| `android_kernel_common_oneplus_sm8750` | `cec4a1056a32dfdd68c23767f6c88bb6c698f1bf` |
| `android_kernel_oneplus_sm8750` | `d71d3c3560fdb45145871ea6491e89e73dfd5ccb` |
| AOSP `external/dtc` | `6ab7e35a241f6b1513c4701c66fe479ab040eafb` |

Apply `common.patch`, `msm-kernel.patch`, and `external-dtc.patch` in their
respective repositories. Each patch was checked in reverse against the local
source workspace from which it was captured.

These patches preserve the build-workspace changes relevant to the released
kernel pair. Vendor-module experiments performed after the known-good build
are not release assets, and the known-failing custom `vendor_boot` and
`vendor_dlkm` images are not distributed.

Patch SHA-256 values:

```text
ef8958f6f1b49a821bdea1d5fa031b52df17b50527a892efea849bc9a52d14a6  common.patch
4ab16fac5a3c512bc20adf04389dcb66470737e2458123d77fea468cefb337e4  external-dtc.patch
f3a013fcebfdae885b429867fd22d7b6aa2703ceea2fbeca1aaa27211645173d  msm-kernel.patch
```
