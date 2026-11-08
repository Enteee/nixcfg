#!/usr/bin/env bash
# Rebuild pond's root disk as UEFI + systemd-boot + LUKS + LVM.
#
# Run from a NixOS installer booted in UEFI MODE, as root:
#
#     bash /mnt/home/ente/nixcfg/machines/pond/install-uefi.sh
#
# This wipes the SSD. It does not touch the md array that holds /home, and it
# asserts that before doing anything destructive.
#
# Everything up to the "POINT OF NO RETURN" banner is read-only checks.

set -euo pipefail

SSD=/dev/disk/by-id/ata-OCZ-VERTEX3_OCZ-T59P986F6605K4SH
ARRAY_NAME=pond:home
ARRAY_UUID=1c658113:dc78dc8a:ee5c29b3:7fb7e336
STATE_TARBALL=pond-state.tar.gz

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31mABORT: %s\033[0m\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------- gates ------

say "GATE 1: must be running from an installer, not from pond itself"
# Any one of these means we are on live media. The NixOS ISO roots / on an
# overlay over a squashfs it mounts at /iso, with the read-only store bind in
# /nix/.ro-store; an installed system has none of those.
root_fs=$(findmnt -no FSTYPE /)
if   [ -d /iso ];            then live="/iso present"
elif [ -d /nix/.ro-store ];  then live="/nix/.ro-store present"
elif [ "$root_fs" = overlay ] || [ "$root_fs" = tmpfs ]; then live="/ is $root_fs"
else
  die "/ is $root_fs and there is no live-media marker.
  This looks like the installed pond. Refusing to repartition the disk it booted from."
fi
echo "  live medium: $live  (/ is $root_fs)"

say "GATE 2: installer must have booted in UEFI mode"
# Checked BEFORE the wipe on purpose. If the firmware is still in CSM/legacy
# mode, discovering that after sgdisk has run would leave pond unbootable with
# nothing to roll back to.
[ -d /sys/firmware/efi ] || die "No /sys/firmware/efi -- this installer booted legacy/CSM.
  Reboot, enter setup (Del/F2), disable CSM or set boot mode to UEFI-only,
  boot the installer again, and re-run. Nothing has been changed."
echo "  /sys/firmware/efi present, efivars: $(ls /sys/firmware/efi/efivars 2>/dev/null | wc -l) entries"

say "GATE 3: the SSD must be the one we think it is"
[ -b "$SSD" ] || die "$SSD not found"
echo "  $SSD -> $(readlink -f "$SSD")"
lsblk -o NAME,SIZE,FSTYPE,LABEL "$(readlink -f "$SSD")"

say "GATE 4: the /home array must be assembled, clean and NOT degraded"
# --homehost=any matters here. The array records homehost `pond`, but the
# installer's hostname is not pond, so without this mdadm treats it as foreign
# and assembles it under an arbitrary /dev/mdN with no /dev/md/home symlink --
# the same mismatch that used to plague this array on pond itself. So resolve
# the device by UUID rather than trusting any name.
mdadm --assemble --scan --homehost=any 2>/dev/null || true
udevadm settle || sleep 2

MD=""
for cand in /dev/md/home /dev/md[0-9]* /dev/md/*; do
  [ -b "$cand" ] || continue
  if mdadm --detail "$cand" 2>/dev/null | grep -q "UUID : $ARRAY_UUID"; then
    MD=$(readlink -f "$cand"); break
  fi
done
[ -n "$MD" ] || die "no md array with UUID $ARRAY_UUID found. Refusing to continue without /home.
  Try: mdadm --assemble --scan --homehost=any ; cat /proc/mdstat"

mdadm --detail "$MD" | grep -q "Name : $ARRAY_NAME" || die "array at $MD is not named $ARRAY_NAME"
state=$(mdadm --detail "$MD" | sed -n 's/^ *State : *//p')
echo "  $MD ($ARRAY_NAME) state: $state"
case "$state" in
  *degraded*|*recovering*|*resyncing*) die "array is '$state'. Wait for clean [2/2] [UU] first:
  a single disk failure while sda is being rebuilt would lose /home." ;;
esac

say "GATE 5: /home must unlock and contain the flake and the state tarball"
if [ ! -e /dev/mapper/crypthome ]; then
  echo "  unlocking $MD (enter the /home passphrase, or the keyslot-1 recovery phrase)"
  cryptsetup open "$MD" crypthome
fi
mkdir -p /mnt/home
mountpoint -q /mnt/home || mount /dev/mapper/crypthome /mnt/home
FLAKE=/mnt/home/ente/nixcfg
[ -f "$FLAKE/flake.nix" ] || die "no flake at $FLAKE"
TARBALL="/mnt/home/$STATE_TARBALL"
[ -f "$TARBALL" ] || die "state tarball missing at $TARBALL.
  Without it ente's password resets, syncthing's uid changes under 76G of data,
  and /home's LUKS keyfile is gone (recoverable only via the Bitwarden phrase)."
echo "  flake:   $FLAKE"
echo "  tarball: $TARBALL ($(du -h "$TARBALL" | cut -f1))"
tar -tzf "$TARBALL" | sed 's/^/    /' | head -12
for want in etc/luks-keys/home var/lib/nixos etc/shadow; do
  tar -tzf "$TARBALL" | grep -q "^$want" || die "tarball is missing $want"
done
echo "  contains etc/luks-keys/home, var/lib/nixos and etc/shadow"

say "GATE 6: the target config must evaluate"
nix --extra-experimental-features 'nix-command flakes' \
  eval --raw "$FLAKE#nixosConfigurations.pond-uefi.config.system.build.toplevel.drvPath" >/dev/null
echo "  .#pond-uefi instantiates"

# --------------------------------------------------- point of no return ------

cat <<'BANNER'

################################################################################
#                            POINT OF NO RETURN                               #
#                                                                              #
#  The next step wipes the SSD. After it, the only way back to a booting pond  #
#  is finishing this script, or restoring from the state tarball by hand.       #
#                                                                              #
#  /home and its md array are NOT touched.                                     #
################################################################################

BANNER
read -rp "Type WIPE to continue: " confirm
[ "$confirm" = "WIPE" ] || die "not confirmed, nothing changed"

say "Partitioning $SSD as GPT: 1G ESP + rest LUKS"
sgdisk --zap-all "$SSD"
sgdisk -n1:0:+1G -t1:ef00 -c1:ESP       "$SSD"
sgdisk -n2:0:0   -t2:8309 -c2:cryptroot "$SSD"
partprobe "$SSD" 2>/dev/null || true
udevadm settle
# The config addresses both of these by GPT partition label, set above.
[ -b /dev/disk/by-partlabel/ESP ] || die "by-partlabel/ESP did not appear"
[ -b /dev/disk/by-partlabel/cryptroot ] || die "by-partlabel/cryptroot did not appear"
echo "  ESP       -> $(readlink -f /dev/disk/by-partlabel/ESP)"
echo "  cryptroot -> $(readlink -f /dev/disk/by-partlabel/cryptroot)"

say "Formatting the ESP"
mkfs.vfat -F32 -n BOOT /dev/disk/by-partlabel/ESP

say "LUKS2 on cryptroot -- you will be asked for a NEW passphrase"
echo "  This is the passphrase pond will ask for at every boot. There is no TPM"
echo "  in this machine, so it cannot be automated. Store it in Bitwarden."
cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/cryptroot
cryptsetup open /dev/disk/by-partlabel/cryptroot cryptroot

say "LVM: vg-pond with a 16G swap LV and root taking the rest"
pvcreate /dev/mapper/cryptroot
vgcreate vg-pond /dev/mapper/cryptroot
# 16 GiB > the 15 GiB of RAM, so a hibernation image always fits.
lvcreate -L 16G      -n swap vg-pond
lvcreate -l 100%FREE -n root vg-pond
mkfs.ext4 -L nixos /dev/vg-pond/root
mkswap  -L swap    /dev/vg-pond/swap
vgs; lvs

say "Mounting the new layout"
mount /dev/vg-pond/root /mnt
mkdir -p /mnt/boot /mnt/home
mount /dev/disk/by-partlabel/ESP /mnt/boot
mountpoint -q /mnt/home || mount /dev/mapper/crypthome /mnt/home
swapon /dev/vg-pond/swap || true
findmnt -R /mnt

say "Installing .#pond-uefi"
# The closure was staged to a plain file:// binary cache on /home before the
# wipe, because /nix lives on the disk being repartitioned -- without this the
# installer would re-download 21 GiB and might have to compile the unfree
# nvidia 470 module against kernel 6.18 from scratch.
#
# require-sigs=false because those paths were copied straight out of pond's own
# store and are therefore unsigned. The cache sits on the encrypted array we
# just unlocked, so its provenance is not in question.
#
# --no-root-passwd because the restored /etc/shadow carries the real hashes.
INSTALL_OPTS=()
if [ -f /mnt/home/nix-cache/nix-cache-info ]; then
  echo "  using staged cache at /mnt/home/nix-cache"
  INSTALL_OPTS+=(
    --option extra-substituters "file:///mnt/home/nix-cache"
    --option require-sigs false
  )
else
  echo "  WARNING: no staged cache found; falling back to cache.nixos.org."
  echo "  Expect a long download, and possibly a local nvidia 470 build."
fi
nixos-install --no-root-passwd --flake "$FLAKE#pond-uefi" "${INSTALL_OPTS[@]}"

say "Restoring preserved state"
# Must land before the first activation: /var/lib/nixos/uid-map is what keeps
# syncthing on uid 237 and therefore still owning /home/syncthing, and
# /etc/luks-keys/home is what unlocks /home without the recovery passphrase.
tar -C /mnt -xzf "$TARBALL"
echo "  restored:"
ls -la /mnt/etc/luks-keys/ | sed 's/^/    /'
echo "    uid-map syncthing: $(grep -o '"syncthing":[0-9]*' /mnt/var/lib/nixos/uid-map || echo MISSING)"
echo "    /mnt/etc/shadow:   $(wc -l < /mnt/etc/shadow) entries"

say "DONE -- what to check after rebooting"
cat <<'NEXT'
  Remove the installer, and while the case is open pull the GTX 660 Ti
  (the idle card; the monitor is on the 680). That power cycle is also what
  finally activates the idle3 setting on the WD drives.

  On first boot, expect exactly ONE passphrase prompt -- for root. /home
  unlocks itself from the restored keyfile.

  Then:
    bootctl status                     # systemd-boot, not grub
    ls /sys/firmware/efi               # exists now
    findmnt / /boot /home
    cat /proc/mdstat                   # still [2/2] [UU]
    stat -c '%U' /home/syncthing       # syncthing, not a number
    nvidia-smi                         # ONE gpu
    systemctl hibernate                # then power on; session should return
    systemctl --failed                 # empty
    sudo idle3ctl -g /dev/disk/by-id/ata-WDC_*   # disabled

  If it does not boot: the installer still works. Unlock /home, and the state
  tarball plus this script will get you back.
NEXT
