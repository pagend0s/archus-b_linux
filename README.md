
# archus-b_linux — Auto Arch USB Boot Medium Creator

> Create a bootable **Arch Linux** USB from a Debian/Ubuntu host — fully automated: partitioning, verified bootstrap download, two-stage chroot install, GRUB setup, and optional RAMROOT.

---

## Table of contents
- #overview
- #features
- #requirements
- #quick-start
- #what-the-scripts-do
- #configuration
- #repository-structure

---

## Overview
**Archus-b** is a collection of Bash scripts that prepare a bootable **Arch Linux** USB stick from a **Debian/Ubuntu** host.  
It takes care of:

* detecting your USB drive and partitioning it (GPT, ESP + root),
* downloading and verifying the official `archlinux-bootstrap-x86_64.tar.zst`,
* extracting the bootstrap and entering a staged chroot,
* installing base packages, configuring locale/keyboard, and
* installing GRUB for UEFI.

---

## Features
- **End-to-end automation**: from internet check to a GRUB-bootable Arch root on USB.
- **Mirror selection by location**: derives country from `timedatectl` and maps it to Arch mirrors; retries on failures.
- **Signature verification**: fetches maintainer key via WKD and `gpg --verify` before extracting.
- **Safety prompts**: asks before destructive partitioning and highlights the selected device.
- **Two-stage chroot**:
  - **Stage 1**: `pacstrap` base system, generate and validate `fstab`, prep for stage 2.
  - **Stage 2**: system config (locale, vconsole, hostname), GRUB install, optional RAMROOT activation.
- **Clean-up**: unmounts bind mounts and purges temp files after chroot.

---

## Requirements
**Host OS**: Debian/Ubuntu (APT available).  
**Privileges**: run **as root** (the main script exits otherwise).  
**Connectivity**: stable internet (downloads & key retrieval).  
**Target USB**: ≤ **32 GB** (current scripts enforce a size limit; see #notes--caveats-please-read).  
**UEFI** firmware (GRUB is installed in UEFI mode with `--removable`).

**Host packages auto-installed** (if missing): `parted`, `dosfstools` (for `mkfs.fat`), `gnupg` (`gpg`), `zstd`, `curl`, `wget`, plus utilities like `fatlabel`, `e2label` (package names may vary on Debian/Ubuntu).

---

## Quick start

```bash
# 1) Clone and enter the repo
git clone https://github.com/pagend0s/archus-b_linux.git archus-b && cd archus-b

# 2) Make scripts executable (if needed)
chmod +x arch_main.sh resources/scripts/*.sh

# 3) Run as root
sudo ./arch_main.sh

# 4) Follow prompts:
#    - Confirm the detected USB device (data will be destroyed)
#    - Wait while the tool partitions, downloads, verifies, and installs
```

After completion, your USB should be UEFI-bootable into the installed Arch environment.

---

## What the scripts do

### Entry point: `arch_main.sh`
- Prints a banner, checks for **root**, exports color vars & `script_dir`.
- Sources sub-scripts in order: `check_packages.sh` → `fdisk_create.sh` → `dowload_and_check.sh` → `extrackt_and_move.sh` → `jail_bootstrap.sh`.

### Host preparation: `check_packages.sh`
- Verifies internet via `ping`.
- Runs `apt update` and ensures required tools (partitioning, filesystems, download, crypto, compression).

### Partitioning: `fdisk_create.sh`
- Detects actual **USB** devices (via `udevadm`), prints them, and **asks for confirmation**.
- If selected device has mounted partitions, tries to **umount** them.
- Enforces **size ≤ 32 GB** (current logic).
- Creates **GPT**:  
  - **Partition 1**: ESP, **1 GB**, flags `boot, esp`, format FAT, label `ARCHEFIBOOT`.  
  - **Partition 2**: root, rest of disk, `ext4`, label `ARCHROOT`.

### Mirror & bootstrap: `dowload_and_check.sh`
- Pulls `https://archlinux.org/download/`, infers **country** (via zoneinfo) and picks a **mirror** for your location.
- Builds URLs to `archlinux-bootstrap-x86_64.tar.zst` and its `.sig`, checks HTTP 200, tries alternative `/pub/linux/archlinux/...` path, and iterates mirrors on error.
- Downloads both files and **verifies** with GPG (imports maintainer key via **WKD**); loops on failure until a good mirror/signature pair is found.

### Extract bootstrap: `extrackt_and_move.sh`
- Creates `resources/Files/arch_chroot/`, detects the downloaded `*.zst`, and extracts with `tar --zstd`.

### Chroot orchestration: `jail_bootstrap.sh`
- Uncomments relevant **mirrorlist** lines for your country.
- Copies helper scripts into the bootstrap root and **patches placeholders** with your actual `root_partition`, `esp_partition`, `time_zone4arch`, and `keyboard_layout`.
- Makes bind mounts for `/dev`, `/dev/pts`, `/proc`, `/sys`, `/run`, then enters **chroot**.
- After exiting, unmounts bind mounts and cleans `resources/Files/`.

### Chroot Stage 1: `in_chroot.sh`
- Initializes pacman keys, runs `pacman -Syyu`.
- Mounts `root_partition` to `/mnt`, runs `pacstrap mnt/ base linux linux-firmware` with a retry mechanism (comments out the top mirror on failures).
- Adjusts `mkinitcpio.conf` (MODULES/HOOKS), generates and **verifies** `fstab`, copying helpers for Stage 2.
- Bind-mounts `/dev`, `/dev/pts`, `/proc`, `/sys`, `/run` into `/mnt` and enters a second chroot.

### Chroot Stage 2: `in_chroot2.sh`
- Sets timezone/locale (`en_US.UTF-8`), keyboard (`KEYMAP`), hostname (`archUSB`).
- Sets **root password** to `qwertz` (you **must change** it later).
- Installs tooling: `grub`, `efibootmgr`, `networkmanager`, `rsync`, `ntfs-3g`, `smartmontools`, `testdisk`, `sudo`, etc.
- Mounts the ESP and installs **GRUB (UEFI)** with `--removable`, generates `grub.cfg`.
- Adds TTY1 **autologin root** override and some GRUB/mkinitcpio tweaks; optionally activates **RAMROOT** (`ramroot_1.1`).
- Cleans pacman cache and unmounts ESP.

---

## Configuration
- **Mirror country mapping**: `resources/scripts/countrys.txt` (list of `CC <Country name>`).  
  *Tip:* The file name has a typo; consider renaming to `countries.txt` and adjusting references.
- **Packages**:  
  - Stage 2 package list is in `in_chroot2.sh` (installed via `pacman_retrying.sh`).  
  - Stage 1 uses `pacstrap` for `base linux linux-firmware` and adjusts `mkinitcpio`.
- **GRUB / kernel parameters**: `in_chroot2.sh` rewrites `GRUB_CMDLINE_LINUX_DEFAULT` with aggressive options (e.g., `nowatchdog`, `mitigations=off`). Tune for your needs.
- **Root password**: hardcoded `qwertz` (change on first boot: `passwd`).
- **RAMROOT** (optional): expects `/home/ramroot_1.1` tree present; see that directory for details.

---

## Repository structure

```
.
├── arch_main.sh
└── resources/
    ├── Files/                      # runtime workspace (download, extract, chroot) — cleaned after run
    └── scripts/
        ├── check_packages.sh
        ├── fdisk_create.sh
        ├── dowload_and_check.sh
        ├── extrackt_and_move.sh
        ├── jail_bootstrap.sh
        ├── in_chroot.sh
        ├── in_chroot2.sh
        ├── replace_hooks.sh
        ├── umount_jail.sh
        ├── Error_handling/
        │   └── pacman_retrying.sh  # required at runtime (copied into chroot); ensure it exists
        └── ramroot_1.1/            # RAMROOT helper (external content)
```

# Additional INFO ;)
If you think I deserve a ☕️, you can send a few 🪙 to Bitcoin address:

1HAK5X4JjnBsJyAaQnpwMMkJRi1MeV7hp3
---
