# Signature verification in UGOS Pro: how it works and whether you can sign yourself

**🌐 Language:** **English** · [中文](../zh/SIGNING.md) · [हिन्दी](../hi/SIGNING.md) · [Español](../es/SIGNING.md) · [Français](../fr/SIGNING.md) · [Русский](../SIGNING.md)

The analysis was done on the firmware `firmware_image-1.16.0.89` (UGOS Pro, Debian 12, amd64).

## Who verifies packages

- **`/usr/sbin/uginstall`** — the installer for `.upk` packages (a Go binary). It is
  the one that parses the `UGREEN-PKG-V2-FORMAT` container, verifies signatures, and unpacks
  the application tree. Strings in the binary: `systemVerify`, `GetVerifyKey`,
  `verifyData`, `un_support_sign_ver`, `parse_package_error`.
- Cryptography: **RSA + SHA-256** (in the binary — `crypto/rsa`, `crypto/sha256`,
  signs of RSA-PSS). The same is confirmed by `upk_pack.py`: the `filesig/usersig/midsig` signatures.

## Root of trust (what is "baked into" the firmware)

The trusted **public** keys live in a read-only partition of the firmware:

```
/rom/usr/ugreen/etc/rsa/ugreenRoot.pub         # root key
/rom/usr/ugreen/etc/rsa/ugreenRootImport.pub   # root key for import
/rom/usr/ugreen/etc/rsa/ugreen.pub             # application-level key
```

`uginstall` reads `ugreenRoot.pub` as the trust anchor. The `/rom` partition is
`fw.squashfs` (a compressed xz squashfs, read-only); it is part of the signed firmware.

## The signing chain

Mapping keys across 19 packages reveals a three-level chain:

```
ugreenRoot (baked into /rom, private key held by UGREEN)
      └── signs the channel intermediate key  (midpub — IDENTICAL across all packages)
                └── signs the build key         (userpub — UNIQUE for each package)
                          └── signs the payload  (filesig/usersig)
```

- `midpub` is identical across all packages → this is the publisher's intermediate key.
- `userpub` is unique for each package → the key of a specific build.
- The package stores only the public parts (`midpub`, `userpub`) and the signatures.

## The main takeaway about "signing yourself"

**The firmware contains only PUBLIC keys. There are no UGREEN private keys there** — and there
shouldn't be (otherwise it would compromise the vendor itself). Therefore:

| Question | Answer |
|---|---|
| Extract the private signing key from the NAS? | **No** — it isn't there, only `.pub`. |
| Sign a modified package for a "stock" NAS? | **No** — you need the private `ugreenRoot`/`mid` key. Forging = breaking RSA. |
| Sign with your own key on your own device? | Technically yes, but only by replacing the trust anchor (see below). Fragile, not recommended. |

### Why "your own signature" is a bad path

For the NAS to accept a package signed with your key, you need to replace
`ugreenRoot.pub` (and the related keys) with your public key. But:

- `/rom` is a read-only squashfs from **signed** firmware; the firmware is verified by
  a separate updater, `ugupdate`, so simply rebuilding the firmware won't work;
- swapping the key at runtime (a bind-mount over `/rom`) won't survive a system
  update and touches system components;
- this breaks the regular authenticity verification of all applications on the device.

## When verification is actually performed

- **The signature is verified only at INSTALL time** of the package (`uginstall`).
- After installation, only the application tree remains in the filesystem
  (`contents/`); the `.upk` itself and the signatures are no longer there.
- **At runtime**, UGOS uses `reconcile` mode: it checks for missing files
  (`reason=files-missing`) and the integrity manifest **`.check-app`** (a JSON
  `path → md5`). The signature is NOT re-verified in the process.

## Practical takeaway for localization

Since the signature is verified only at install time, and the application then runs from a folder
on disk — **you add your own localization on top of the installed application, without
re-signing**. It is enough to edit the locale files and update `.check-app`
(so that the runtime `reconcile` passes). Ready-made scripts and instructions are
in [LOCALIZATION.md](LOCALIZATION.md).
