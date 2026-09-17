{ pkgs, lib, ... }:

let
  systemdInhibit = lib.getExe' pkgs.systemd "systemd-inhibit";
  sleepBin = lib.getExe' pkgs.coreutils "sleep";

  # handle-lid-switch is load-bearing, not redundant. logind's
  # LidSwitchIgnoreInhibited defaults to "yes", so on lid close it ignores the
  # high-level "sleep" and "idle" locks. Low-level locks such as
  # handle-lid-switch are always honored regardless of that setting
  # (logind.conf(5)), so this is what keeps a closed lid from suspending.
  lockTypes = "sleep:idle:handle-lid-switch";

  unit = "nosuspend-hold.service";

  nosuspend = pkgs.writeShellApplication {
    name = "nosuspend";
    runtimeInputs = with pkgs; [ systemd coreutils procps ];
    text = ''
      usage() {
        cat <<'EOF'
      nosuspend — keep the machine awake by holding a logind inhibitor lock.

      The persistent hold lives in the nosuspend-hold user unit, not in this
      process, so it survives a restart of the status bar, i3, or this shell.

      Usage:
        nosuspend                 Toggle the persistent hold.
        nosuspend on | off        Turn the persistent hold on or off.
        nosuspend toggle          Same as no arguments.
        nosuspend status          Print "blocked" or "auto"; exit 0 if held.
        nosuspend json            Emit i3status-rust JSON for the bar block.
        nosuspend run <cmd>...    Run <cmd> under its own inhibitor, which is
                                  released as soon as <cmd> exits. Independent
                                  of the persistent hold.
        nosuspend -h | --help     Show this help.

      Notes:
        Blocks suspend, the idle action and the lid switch. Screen locking is
        unaffected — xautolock/i3lock still lock the screen behind it.
      EOF
      }

      # Tell i3status-rust to refresh the block immediately rather than waiting
      # for its poll interval. Harmless if i3status-rs is not running.
      #
      # -f is required: nixpkgs wraps the binary, so the process comm is
      # ".i3status-rs-wr" (truncated to 15 chars) and a plain comm match never
      # finds it. Matching the full command line does. The pattern is anchored
      # on "/bin/i3status-rs" rather than the bare name so that it cannot match
      # an unrelated shell that merely mentions i3status-rs in its arguments.
      refresh_bar() {
        pkill -SIGRTMIN+4 -f '/bin/i3status-rs' 2>/dev/null || true
      }

      is_held() {
        systemctl --user is-active --quiet ${unit}
      }

      case "''${1-toggle}" in
        -h|--help)
          usage
          ;;
        on)
          systemctl --user start ${unit}
          refresh_bar
          ;;
        off)
          systemctl --user stop ${unit}
          refresh_bar
          ;;
        toggle)
          if is_held; then
            systemctl --user stop ${unit}
          else
            systemctl --user start ${unit}
          fi
          refresh_bar
          ;;
        status)
          if is_held; then
            echo blocked
          else
            echo auto
            exit 1
          fi
          ;;
        json)
          if is_held; then
            printf '{"state":"Warning","text":"SUSPEND: BLOCKED"}\n'
          else
            printf '{"state":"Idle","text":"SUSPEND: auto"}\n'
          fi
          ;;
        run)
          shift
          if [ $# -eq 0 ]; then
            echo "nosuspend: run needs a command" >&2
            exit 2
          fi
          exec ${systemdInhibit} --what=${lockTypes} --mode=block \
            --who=nosuspend --why="running: $*" -- "$@"
          ;;
        *)
          echo "nosuspend: unknown argument: $1" >&2
          usage >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ nosuspend ];

  # Deliberately no wantedBy: this unit is started on demand only, by the
  # nosuspend CLI or by clicking the status bar block.
  systemd.user.services.nosuspend-hold = {
    description = "Hold a logind suspend inhibitor lock";
    serviceConfig = {
      Type = "exec";
      ExecStart = "${systemdInhibit} --what=${lockTypes} --mode=block "
        + "--who=nosuspend --why=\"persistent hold\" ${sleepBin} infinity";
    };
  };
}
