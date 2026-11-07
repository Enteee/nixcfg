{ pkgs, lib, ... }:

# Disable the idle3 head-parking timer on the WD Green drives.
#
# These WD20EARX ship with idle3 set to 80 (0x50) = 8.0 seconds, so the heads
# unload after eight seconds of inactivity and reload on the next access. On a
# drive holding a filesystem that is touched irregularly this burns load/unload
# cycles very fast, and it is the one wear mechanism actually aging these disks:
# SMART shows 0 reallocated sectors and only ~6100 power-on hours, but 381k and
# 361k load cycles against a rating of roughly 300k.
#
# Note the setting lives in the drive's own non-volatile config and takes effect
# at the next *power cycle*, not at the next warm reboot. Check with
# `idle3ctl -g /dev/disk/by-id/ata-WDC_*` and 193 Load_Cycle_Count in smartctl.

let
  disableIdle3 = pkgs.writeShellApplication {
    name = "wd-idle3-disable";
    runtimeInputs = with pkgs; [ idle3tools coreutils gnugrep ];
    text = ''
      shopt -s nullglob
      for dev in /dev/disk/by-id/ata-WDC_*; do
        case "$dev" in *-part*) continue ;; esac

        state="$(idle3ctl -g "$dev" 2>&1 || true)"

        # Idempotent: only write when a timer is actually set, so a reboot does
        # not re-write the drive's config area for nothing.
        if printf '%s' "$state" | grep -qi "disabled"; then
          echo "$dev: idle3 already disabled"
        else
          echo "$dev: $state -- disabling"
          idle3ctl -d "$dev" || echo "$dev: idle3ctl failed, continuing"
        fi
      done
    '';
  };
in
{
  environment.systemPackages = [ pkgs.idle3tools ];

  systemd.services.wd-idle3 = {
    description = "Disable the WD Green idle3 head-parking timer";
    wantedBy = [ "multi-user.target" ];
    # The by-id symlinks come from udev, and reading the drives needs them
    # settled. This is cheap and idempotent, so ordering late is fine.
    after = [ "systemd-udev-settle.service" "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = lib.getExe disableIdle3;
    };
  };
}
