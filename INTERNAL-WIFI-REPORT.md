# Internal Wi-Fi management-frame investigation

Tested on a retail OnePlus 13 CPH2655 running
`CPH2655_15.0.0.850(EX01)` and kernel
`6.6.56-android15-8-o-gcec4a1056a32-4k`.

## Result

The stock, already-loaded Qualcomm stack exposes a usable management-frame
submission path through `NL80211_CMD_FRAME` and the driver's existing
`cfg80211_ops.mgmt_tx` callback. Replacing `cnss2` or
`qca_cld3_peach_v2` is not necessary to reach this path.

This is a narrower result than full packet injection:

- **Proven:** cfg80211 accepts serialized management frames and hands them to
  the stock driver's management-TX path.
- **Not yet proven:** successful over-the-air deauthentication, firmware
  preservation of caller-supplied addresses, or arbitrary data-frame
  injection through a monitor netdev.

## Live evidence

The live wiphy advertises monitor mode, the `frame` command, and management TX
frame types. A harmless probe request using the interface address was accepted
and generated an `acked` management-TX-status event.

A probe request with an arbitrary transmitter address was rejected with
`EINVAL`. Source review confirmed that this happens in cfg80211 before the
driver: random transmitter addresses are not generally allowed for probe
requests.

The live wiphy already has
`NL80211_EXT_FEATURE_AUTH_AND_DEAUTH_RANDOM_TA` set. The Android `iw` build on
the tested firmware is too old to print the name of that newer feature bit.

With explicit authorization, exactly one reason-code-7 unicast
deauthentication frame was then submitted against the test host's own client
connection. Identifying MAC addresses have been redacted:

```text
NL80211_CMD_FRAME accepted: if=wlan2 index=31 freq=2412
DA=<authorized-client>
SA=<phone-hotspot-bssid>
BSSID=<phone-hotspot-bssid>
reason=7 len=26
```

The asynchronous status was:

```text
wlan2 (phy #0): mgmt TX status (cookie 100): no ack
```

The client remained connected throughout the observation window. No retry was
sent. Therefore command acceptance is real, but this test alone does not prove
that the firmware placed the frame on the air.

## Driver-path review

The shipped `qca_cld3_peach_v2.ko` contains the expected management-TX
functions and installs `wlan_hdd_mgmt_tx` through the public `cfg80211_ops`
table. Local matching source shows that the frame is copied into the driver's
TX context. Lower peer selection checks an associated unicast destination
before falling back to source/self-peer selection.

The existing experimental `fix/hidden-vdev-state` branch is not required for
this nl80211 route. Its monitor-netdev patch also reads `skb->len` after
`wlan_mgmt_txrx_mgmt_frame_tx()` succeeds, even though the patch states that
the callee takes ownership of the skb on success. Save the length before the
handoff if that branch is revisited.

Correction to an earlier review note: commit `7f9e3b2` does not contain a
literal duplicate `qdf_nbuf_free(skb)` at its common drop label. The supported
warning is the post-handoff skb access described above.

## Next decisive test

Use an independent monitor radio on the same channel while submitting one
authorized management frame. Inspect the captured transmitter/source/BSSID,
FCS, retry flag, and ACK behavior. If the frame is absent, instrument the
stock qcacld management-TX completion path. Do not return to the custom
`cnss2` replacement merely to test this stock path: that replacement is known
to watchdog-reset the tested phone.

Only test networks and clients you own or are explicitly authorized to assess.
