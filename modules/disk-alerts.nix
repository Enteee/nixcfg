{ config, pkgs, lib, ... }:

let
  # Shared tail for both alert wrappers. Each wrapper sets $title and $body,
  # then this does the delivering.
  #
  # Order matters: logger and wall come first and are unconditional, because
  # they work with nobody logged in -- which is exactly when a disk is most
  # likely to be quietly dying. The i3 nag bar is best effort on top.
  #
  # mdadm and smartd both run their handlers as root from a service with no
  # session attached, so reaching the desktop means finding it. Reading
  # DISPLAY/XAUTHORITY out of the running i3 process follows the session rather
  # than assuming :0 and ~/.Xauthority -- which is the bug that left NixOS's own
  # smartd notifier dead (it exported a literal `DISPLAY=:`).
  deliver = ''
    logger -t disk-alert -p daemon.err -- "$title: $body"
    printf '%s\n\n%s\n' "$title" "$body" | wall 2>/dev/null || true

    i3pid="$(pgrep -u ente -x i3 | head -1 || true)"
    [ -n "$i3pid" ] || exit 0

    env_of() {
      tr '\0' '\n' < "/proc/$i3pid/environ" | sed -n "s/^$1=//p" | head -1
    }

    DISPLAY="$(env_of DISPLAY)"
    [ -n "$DISPLAY" ] || exit 0
    XAUTHORITY="$(env_of XAUTHORITY)"
    I3SOCK="$(env_of I3SOCK)"
    export DISPLAY XAUTHORITY I3SOCK

    i3-nagbar -t error -m "$title: $body" >/dev/null 2>&1 &
  '';

  mkAlert = name: preamble: pkgs.writeShellApplication {
    inherit name;
    runtimeInputs = with pkgs; [ coreutils util-linux procps i3 gnused ];
    text = preamble + deliver;
  };

  # mdadm passes event information as positional arguments:
  #   $1 event, $2 md device, $3 component device (only for some events)
  mdadmAlert = mkAlert "mdadm-alert" ''
    title="mdadm: ''${1:-unknown event}"
    body="''${2:-unknown array}''${3:+ (''${3})}"
  '';

  # smartd passes nothing positionally; everything arrives in the environment.
  smartdAlert = mkAlert "smartd-alert" ''
    title="smartd: ''${SMARTD_DEVICESTRING:-unknown device}"
    body="''${SMARTD_MESSAGE:-''${SMARTD_FULLMESSAGE:-no message}}"
  '';
in
{
  # Route smartd through our notifier instead of the one NixOS generates.
  #
  # The module builds `DEFAULT -m <nomailer> -M exec <its script> ${monitored}`,
  # so appending a second -M exec here wins: smartd honours the last one and
  # NixOS's script never executes. Verified by running smartd -q onecheck
  # against a config with two -M exec entries and seeing only the latter fire.
  #
  # Consequence worth knowing: services.smartd.notifications.{wall,x11,mail}
  # now have no effect, because the script those options configure is the one
  # being bypassed. This notifier does wall itself, and does the X part
  # properly. NixOS's x11 path was broken anyway -- notifications.x11.display
  # defaults to ":", and `DISPLAY=: xmessage` fails with "Can't open display".
  services.smartd.defaults.monitored = "-a -M exec ${lib.getExe smartdAlert}";

  # Same notifier for array-level events. Setting PROGRAM is also what keeps
  # mdmon from crashing on start: the swraid module warns when neither MAILADDR
  # nor PROGRAM is configured, and pond's mdadm.conf was empty.
  #
  # PROGRAM over MAILADDR because there is no MTA on either machine, so mail
  # would land in a local spool nobody reads.
  boot.swraid.mdadmConf = ''
    PROGRAM ${lib.getExe mdadmAlert}
  '';
}
