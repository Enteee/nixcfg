{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/basesystem.nix
    ../../modules/nosuspend.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/07dd092f-0190-492d-ad19-a1fac5849915";
      preLVM = true;
      allowDiscards = true;
    };
  };

  networking.hostName = "puddle";

  # ModemManager.service does not seem to be started when network
  # manager tries to communicate over dbus
  # https://github.com/NixOS/nixpkgs/issues/11197
  systemd.services.ModemManager.wantedBy = [ "multi-user.target" ];

  services.udev = {
    packages = with pkgs; [
      qFlipper
    ];
  };

  # powerManagement.powertop.enable is deliberately absent: it runs
  # `powertop --auto-tune` at boot, which flips power/control to "auto" on every
  # USB device, HID included. TLP's own docs warn against running both tuners.
  # The powertop binary is still installed below for diagnostics.

  # Enable TLP power management daemon
  services.tlp = {
    enable = true;
    settings = {
      # Keep USB autosuspend off. The corded mouse and keyboard hang off the
      # DisplayLink dock behind four chained hubs, none of which have remote
      # wakeup enabled, so once the 2s idle timer suspends the mouse its motion
      # reports are dropped until a button press resumes it -- the pointer looks
      # frozen. Autosuspend on a few always-attached peripherals saves almost no
      # power, so disable it wholesale rather than maintaining a USB_DENYLIST
      # that silently breaks whenever a device moves to another dock port.
      USB_AUTOSUSPEND = 0;
    };
  };

  # Enable bluetooth
  services.blueman.enable = true;

  # bluetooth with pipewire
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Enable="Source,Sink,Media,Socket";
      };
    };
  };

  services.logind.settings.Login.HandleLidSwitch = "suspend";

  services.xserver = {
    videoDrivers = [
      "displaylink"
      "modesetting"
    ];
  };

  # Pre-create the two evdi DRM devices at module load instead of letting
  # DisplayLinkManager create them when the dock is plugged in.
  #
  # Without this, plugging the dock into a running session makes X hot-add two
  # brand-new PRIME GPU screens; autorandr then immediately applies the
  # "docked" profile, and the modesetting driver segfaults while setting up
  # shared-pixmap flipping on a provider it only learned about ~700ms earlier:
  #
  #   (EE) 3: modesetting_drv.so  -> msEnableSharedPixmapFlipping
  #   (EE) 4: X (RRCrtcSet+0x9e0)
  #   (EE) 5: X (ProcRRSetCrtcConfig+0x2c2)
  #   (EE) Segmentation fault at address 0x29
  #
  # X dying takes i3 with it and drops us back at lightdm. It reproduced on
  # every boot, always on the *first* dock plug of that X server and never
  # afterwards -- once the providers are registered, further plug/unplug cycles
  # only change connector state and are handled fine. Creating the devices at
  # boot puts them on that known-good path: X registers both GPU screens during
  # startup, and plugging the dock becomes a connector/EDID change rather than
  # a provider hot-add.
  #
  # Count is 2 because the ThinkPad Hybrid dock exposes two DisplayLink heads
  # (DVI-I-1-1 and DVI-I-2-2). Raise it if a dock with more heads shows up,
  # otherwise the extra one falls back to being hot-added.
  boot.extraModprobeConfig = ''
    options evdi initial_device_count=2
  '';

  # Let DRM hotplug events settle before reconfiguring outputs.
  #
  # autorandr's own udev rule (40-monitor-hotplug.rules, from pkgs.autorandr)
  # fires on *every* ACTION=="change" SUBSYSTEM=="drm" event with no delay. The
  # dock emits a burst of them -- connector state and EDID property changes on
  # both evdi cards -- while its chained USB hubs are still enumerating, so
  # autorandr starts resizing the root framebuffer and setting CRTCs on
  # hardware that is still appearing. The stock unit already rate-limits itself
  # to one start per 5s (startLimitBurst = 1), so sleeping here just moves that
  # single run to after the burst instead of into the middle of it.
  systemd.services.autorandr.serviceConfig.ExecStartPre = "${lib.getExe' pkgs.coreutils "sleep"} 4";

  # Enable touchpad support.
  services.libinput.enable = true;

  # Screen backlight. 'light' was removed from nixpkgs in 26.05 (unmaintained
  # upstream); actkbd runs as root, so brightnessctl needs no setuid wrapper.
  environment.systemPackages = [ pkgs.brightnessctl pkgs.powertop ];
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 224 ]; events = [ "key" ]; command = "${lib.getExe pkgs.brightnessctl} set 10%-"; }
      { keys = [ 225 ]; events = [ "key" ]; command = "${lib.getExe pkgs.brightnessctl} set +10%"; }
    ];
  };

  system.stateVersion = "18.09";

}
