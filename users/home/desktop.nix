{
  pkgs,
  config,
  lib,
  osConfig,
  ...
}:

# Display, window manager and status bar.
#
# These stay in one module because they are genuinely interdependent rather
# than merely related: `loadBackground` is used by both an autorandr postswitch
# hook and xsession.initExtra, i3-msg is used by both a hook and every status
# block, and the autorandr hooks deliberately override the Xft.dpi and *.font
# set in xresources.properties below. Splitting them would mean threading those
# values between files for no gain.

let
  autorandr = lib.getExe pkgs.autorandr;
  xrdb = lib.getExe' pkgs.xrdb "xrdb";
  cat = lib.getExe' pkgs.coreutils "cat";
  i3-msg = lib.getExe' pkgs.i3 "i3-msg";
  feh-cmd = lib.getExe pkgs.feh;

  i3Modifier = "Mod4";

  # Read back out of the module system rather than redefined, so the keybinding
  # and the idle locker can never drift apart. Set in ./services.nix.
  lockCmd = config.services.screen-locker.lockCmd;

  lockSuspend = pkgs.writeShellScript "lockAndSuspend.sh" ''
    ${lockCmd} && systemctl suspend
  '';

  loadBackground = pkgs.writeShellScript "load-background.sh" ''
    if [ -e $HOME/.background-image ]; then
      ${feh-cmd} --bg-scale $HOME/.background-image
    fi
  '';

  # i3bar only does its own scroll-to-switch-workspace handling over bar area
  # that the status command does not cover. Because i3status-rust turns on the
  # click-events protocol, every button press over a block — wheel included —
  # is forwarded to it instead, so each block has to re-implement the scroll
  # behaviour the bar used to provide for free. Directions match i3bar:
  # wheel up = previous workspace, wheel down = next.
  scrollWorkspaces = ''
    [[block.click]]
    button = "up"
    cmd = "${i3-msg} workspace prev_on_output"

    [[block.click]]
    button = "down"
    cmd = "${i3-msg} workspace next_on_output"
  '';

  # puddle is the laptop, pond the desktop. These three blocks describe hardware
  # only puddle has. They used to be emitted on both machines and merely hidden
  # on pond by `missing_format = ""` -- which worked, but left three blocks
  # polling every interval for devices that cannot exist there.
  isLaptop = osConfig.networking.hostName == "puddle";

  laptopBlocks = ''
    # Was i3status "wireless _first_": W: (%quality at %essid) %ip
    # The old separate "ipv6" block is folded in as format_alt on the network
    # blocks — click to swap between the v4 and v6 address.
    [[block]]
    block = "net"
    device = "wlp61s0"
    format = " W: ($signal_strength at $ssid) $ip "
    format_alt = " W: $ipv6 "
    inactive_format = " W: down "
    missing_format = ""
    ${scrollWorkspaces}

    # Was i3status "wireless wwp0s20f0u6": W: %ip
    [[block]]
    block = "net"
    device = "wwp0s20f0u6"
    format = " W: $ip "
    inactive_format = " W: down "
    missing_format = ""
    ${scrollWorkspaces}

    # Was i3status "battery all": %status %percentage %remaining. Only BAT0
    # exists on this machine. i3status-rust picks a different format per state
    # and the defaults for those are icon-only, so each one is set explicitly —
    # otherwise a full battery renders as an empty block.
    [[block]]
    block = "battery"
    device = "BAT0"
    interval = 10
    format = " BAT $percentage {$time_remaining.dur(hms:true, min_unit:m) |}"
    charging_format = " BAT chr $percentage {$time_remaining.dur(hms:true, min_unit:m) |}"
    full_format = " BAT full $percentage "
    not_charging_format = " BAT idle $percentage "
    empty_format = " BAT EMPTY "
    missing_format = ""
    ${scrollWorkspaces}
  '';

  # i3status-rust. Block order here is the on-screen order, left to right.
  # "plain" theme + no icons keeps the previous plain-text look, which matters
  # because the bar font is not a Nerd Font.
  i3StatusConfig = pkgs.writeText "i3status-rust.toml" ''
    [theme]
    theme = "plain"

    [icons]
    icons = "none"

    ${lib.optionalString isLaptop laptopBlocks}

    # Was i3status "ethernet _first_": E: %ip (%speed). The device regex
    # matches both the built-in port and the dock port. i3status-rust has no
    # link-speed placeholder, so this shows throughput instead.
    [[block]]
    block = "net"
    device = "^enp"
    format = " E: $ip ($speed_down/$speed_up) "
    format_alt = " E: $ipv6 "
    inactive_format = " E: down "
    missing_format = ""
    ${scrollWorkspaces}

    # Was i3status "disk /": %avail
    [[block]]
    block = "disk_space"
    path = "/"
    info_type = "available"
    interval = 20
    warning = 20.0
    alert = 10.0
    format = " / $available.eng(prefix:Gi) "
    ${scrollWorkspaces}

    # Was i3status "load": %1min
    [[block]]
    block = "load"
    interval = 5
    format = " $1m.eng(w:4) "
    ${scrollWorkspaces}

    # Was i3status "memory": %used | %available. Note the separator is "/" and
    # not "|": a bare pipe is the alternative-branch operator in i3status-rust
    # format strings and silently swallows everything after it.
    [[block]]
    block = "memory"
    interval = 5
    format = " $mem_used.eng(prefix:Gi) / $mem_avail.eng(prefix:Gi) "
    ${scrollWorkspaces}

    # Suspend inhibitor toggle. State and the click action both go through the
    # nosuspend CLI, which drives the nosuspend-hold user unit — so the lock
    # outlives a restart of this bar. signal = 4 lets the CLI refresh the block
    # instantly when toggled from a terminal (SIGRTMIN+4).
    [[block]]
    block = "custom"
    command = "nosuspend json"
    json = true
    interval = 60
    signal = 4
    [[block.click]]
    button = "left"
    cmd = "nosuspend toggle"
    update = true
    ${scrollWorkspaces}

    # Was i3status "tztime local": %Y-%m-%d %H:%M:%S
    [[block]]
    block = "time"
    interval = 1
    format = " $timestamp.datetime(f:'%Y-%m-%d %H:%M:%S') "
    ${scrollWorkspaces}

  '';
in
{
  home.file = lib.optionalAttrs isLaptop {
    # Disable Vertical Synchronization: DisplayLink has
    # problems when vsync is enabled.
    # https://github.com/DisplayLink/evdi/issues/186
    #
    # puddle-only. It was deployed on both machines, but pond is
    # videoDrivers = [ "nvidia" ] with no DisplayLink anywhere, so there it
    # just disabled vsync for a dock that is not attached.
    ".drirc".text = ''
      <device screen="0" driver="dri2">
        <application name="Default">
          <option name="vblank_mode" value="0"/>
        </application>
      </device>
    '';
  };

  programs.autorandr = {
    enable = true;

    hooks.postswitch = {
      "notify-i3" = "${i3-msg} restart";
      "load-background" = "${loadBackground}";
    };

    profiles = {
      undocked = {
        fingerprint = {
          eDP-1 = "00ffffffffffff0006af362300000000001b0104a51f117802f4f5a4544d9c270f505400000001010101010101010101010101010101e65f00a0a0a040503020350035ae100000180000000f0000000000000000000000000020000000fe0041554f0a202020202020202020000000fe004231343051414e30322e33200a00b2";
        };
        config = {
          eDP-1 = {
            enable = true;
            gamma = "1.0:0.667:0.455";
            mode = "2560x1440";
            position = "0x0";
            primary = true;
            rate = "60.01";
          };
          DVI-I-1-1 = {
            enable = false;
          };
          DVI-I-2-2 = {
            enable = false;
          };
        };
        hooks.postswitch = ''
          ${cat} <<EOF | ${xrdb} -merge -
            Xft.dpi:  144
            *.font:   xft:Inconsolata Regular:family=mono:pixelsize=22:antialias=true
          EOF
        '';
      };

      docked = {
        fingerprint = {
          DVI-I-1-1 = "00ffffffffffff004c2d670b3336333032180103803c22782a9791a556549d250e5054bfef80714f81c0810081809500a9c0b3000101023a801871382d40582c450056502100001e011d007251d01e206e28550056502100001e000000fd00324b1e5111000a202020202020000000fc00533237443339300a202020202001d402031af14690041f130312230907078301000066030c00100080011d00bc52d01e20b828554056502100001e8c0ad090204031200c4055005650210000188c0ad08a20e02d10103e9600565021000018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061";
          DVI-I-2-2 = "00ffffffffffff004c2d670b3336333006190103803c22782a9791a556549d250e5054bfef80714f81c0810081809500a9c0b3000101023a801871382d40582c450056502100001e011d007251d01e206e28550056502100001e000000fd00324b1e5111000a202020202020000000fc00533237443339300a202020202001ff02031af14690041f130312230907078301000066030c00100080011d00bc52d01e20b828554056502100001e8c0ad090204031200c4055005650210000188c0ad08a20e02d10103e9600565021000018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061";
          eDP-1 = "00ffffffffffff0006af362300000000001b0104a51f117802f4f5a4544d9c270f505400000001010101010101010101010101010101e65f00a0a0a040503020350035ae100000180000000f0000000000000000000000000020000000fe0041554f0a202020202020202020000000fe004231343051414e30322e33200a00b2";
        };
        config = {
          eDP-1 = {
            enable = false;
          };
          DVI-I-1-1 = {
            enable = true;
            gamma = "1.0:0.667:0.455";
            position = "0x0";
            mode = "1920x1080";
            primary = true;
            rate = "60.00";
          };
          DVI-I-2-2 = {
            enable = true;
            mode = "1920x1080";
            gamma = "1.0:0.667:0.455";
            position = "1920x0";
            rate = "60.00";
          };
        };
        hooks.postswitch = ''
          ${cat} <<EOF | ${xrdb} -merge -
            Xft.dpi:  120
            *.font:   xft:Inconsolata Regular:family=mono:pixelsize=17:antialias=true
          EOF
        '';
      };

      # pond. Every other profile here fingerprints puddle's eDP-1, so none of
      # them could ever match on pond -- `autorandr --change` was a no-op and
      # the postswitch hooks (notify-i3, load-background) never ran there.
      #
      # That was not only cosmetic: xresources.properties below sets
      # Xft.dpi = 144 for both machines, which is right for puddle's 2560x1440
      # 14" panel but leaves pond rendering ~1.75x oversized on a 1920x1080
      # 27" monitor. The docked hook that corrects it to 120 never fired.
      #
      # This is in fact the same physical monitor as docked's DVI-I-2-2 -- the
      # EDID, serial included, is identical -- so it reuses docked's 120 / 17
      # rather than the panel's true ~82 DPI.
      #
      # No `gamma` here on purpose: redshift (configured in ./services.nix) owns
      # gamma and rewrites it continuously by time of day, so setting it at
      # switch time would just be overwritten.
      pond = {
        fingerprint = {
          HDMI-0 = "00ffffffffffff004c2d670b3336333006190103803c22782a9791a556549d250e5054bfef80714f81c0810081809500a9c0b3000101023a801871382d40582c450056502100001e011d007251d01e206e28550056502100001e000000fd00324b1e5111000a202020202020000000fc00533237443339300a202020202001ff02031af14690041f130312230907078301000066030c00100080011d00bc52d01e20b828554056502100001e8c0ad090204031200c4055005650210000188c0ad08a20e02d10103e9600565021000018000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061";
        };
        config = {
          HDMI-0 = {
            enable = true;
            mode = "1920x1080";
            position = "0x0";
            primary = true;
            rate = "60.00";
          };
        };
        hooks.postswitch = ''
          ${cat} <<EOF | ${xrdb} -merge -
            Xft.dpi:  120
            *.font:   xft:Inconsolata Regular:family=mono:pixelsize=17:antialias=true
          EOF
        '';
      };

    };
  };

  xsession = {

    enable = true;

    numlock.enable = true;

    initExtra = ''
      ${loadBackground}
    '';

    windowManager = {
      i3 = {
        enable = true;
        config = {
          modifier = i3Modifier;
          startup = [
            {
              command = "${autorandr} --change";
            }
          ];

          focus.followMouse = false;

          bars = [
            {
              position = "bottom";
              statusCommand = "${lib.getExe' pkgs.i3status-rust "i3status-rs"} ${i3StatusConfig}";
            }
          ];

          window.titlebar = false;

          window.commands = [
            {
              command = "move down";
              criteria = {
                class = "Remote-viewer";
              };
            }
          ];

          floating.criteria = [
            {
              class = "^Steam$";
              instance = "^Steam$";
            }
          ];

          keybindings =
            with config.xsession.windowManager.i3.config;
            lib.mkOptionDefault {

              "${modifier}+j" = "focus down";
              "${modifier}+h" = "focus left";
              "${modifier}+l" = "focus right";
              "${modifier}+k" = "focus up";

              "${modifier}+Shift+j" = "move down";
              "${modifier}+Shift+h" = "move left";
              "${modifier}+Shift+l" = "move right";
              "${modifier}+Shift+k" = "move up";

              "${modifier}+c" = "split h";
              "${modifier}+a" = "focus parent";

              "${modifier}+Down" = "move workspace to output down";
              "${modifier}+Left" = "move workspace to output left";
              "${modifier}+Right" = "move workspace to output right";
              "${modifier}+Up" = "move workspace to output up";

              "${modifier}+Shift+Down" = "move container to output down";
              "${modifier}+Shift+Left" = "move container to output left";
              "${modifier}+Shift+Right" = "move container to output right";
              "${modifier}+Shift+Up" = "move container to output up";

              "${modifier}+o" = "exec --no-startup-id ${lockCmd}";
              "${modifier}+p" = "exec --no-startup-id ${lockSuspend}";
            };

          modes = {
            resize = {
              Up = "resize grow up 10 px or 10 ppt";
              Down = "resize grow down 10 px or 10 ppt";
              Left = "resize grow left 10 px or 10 ppt";
              Right = "resize grow right 10 px or 10 ppt";

              "Shift+Up" = "resize shrink up 10 px or 10 ppt";
              "Shift+Down" = "resize shrink down 10 px or 10 ppt";
              "Shift+Left" = "resize shrink left 10 px or 10 ppt";
              "Shift+Right" = "resize shrink right 10 px or 10 ppt";

              k = "resize grow up 10 px or 10 ppt";
              j = "resize grow down 10 px or 10 ppt";
              h = "resize grow left 10 px or 10 ppt";
              l = "resize grow right 10 px or 10 ppt";

              "Shift+k" = "resize shrink up 10 px or 10 ppt";
              "Shift+j" = "resize shrink down 10 px or 10 ppt";
              "Shift+h" = "resize shrink left 10 px or 10 ppt";
              "Shift+l" = "resize shrink right 10 px or 10 ppt";

              Escape = "mode default";
              Return = "mode default";
            };
          };
        };
      };
    };
  };

  # Xft.dpi and *.font here are the undocked/puddle defaults; the autorandr
  # postswitch hooks above override both per display profile.
  xresources.properties = {
    "*background" = "rgb:10/10/10";
    "*foreground" = "rgb:d3/d3/d3";
    "*color0" = "rgb:10/10/10";
    "*color1" = "rgb:cd/5c/5c";
    "*color2" = "rgb:2e/8b/57";
    "*color3" = "rgb:f0/e6/8c";
    "*color4" = "rgb:b0/c4/de";
    "*color5" = "rgb:ba/55/d3";
    "*color6" = "rgb:46/82/b4";
    "*color7" = "rgb:d3/d3/d3";
    "*color8" = "rgb:4d/4d/4d";
    "*color9" = "rgb:ff/6a/6a";
    "*color10" = "rgb:8f/bc/8f";
    "*color11" = "rgb:ff/fa/cd";
    "*color12" = "rgb:1e/90/ff";
    "*color13" = "rgb:db/70/93";
    "*color14" = "rgb:5f/9e/a0";
    "*color15" = "rgb:ff/ff/ff";

    "*.font" = "xft:Inconsolata Regular:family=mono:pixelsize=22:antialias=true";

    "Xft.dpi" = 144;
    "Xft.autohint" = false;
    "Xft.lcdfilter" = "lcddefault";
    "Xft.hintstyle" = "hintfull";
    "Xft.hinting" = true;
    "Xft.antialias" = true;
    "Xft.rgba" = "rgb";
  };
}
