{ pkgs, lib, ... }:

# Shell and terminal emulator.
#
# Colours and the default font live in xresources.properties over in
# desktop.nix, because the autorandr postswitch hooks override Xft.dpi and
# *.font per display profile.

let
  custom-rxvt-unicode = pkgs.rxvt-unicode.override {
    configure =
      { availablePlugins, ... }:
      {
        plugins = with availablePlugins; [
          autocomplete-all-the-things
          font-size
        ];
      };
  };
in
{
  programs.bash = {
    enable = true;
    initExtra = ''
      if [ ! -z "''${SHELL_NAME}" ]; then
        export PS1="\e[0;31m(''${SHELL_NAME})\e[m ''${PS1}"
      fi

      if [ ! -z ''${ASCIINEMA_REC+x} ]; then
        export PS1="$ "
      fi

      function ipython-nix {
        packages=""
        for arg in $@; do
            packages="$packages $arg"
        done
        nix-shell -p "with python3Packages; [ ipython $packages ]" --command ipython
      }
    '';
  };

  programs.urxvt = {
    enable = true;
    package = custom-rxvt-unicode;
    fonts = [ ];
    scroll.bar.enable = false;
    extraConfig = {
      "saveLines" = 1000;
      "secondaryScroll" = "off";
      "shading" = 20;

      "scrollTtyOutput" = false;
      "scrollWithBuffer" = true;
      "scrollTtyKeypress" = true;

      "perl-ext" = "default,matcher";
      "url-launcher" = lib.getExe pkgs.firefox;
      "matcher.button" = 2;

      "perl-ext-common" = "autocomplete-ALL-the-things,font-size";

      "keysym.M-C-slash" = "perl:aAtt:word-complete";
      "keysym.M-question" = "perl:aAtt:fuzzy-complete";
      "keysym.M-quotedbl" = "perl:aAtt:undo";

      "keysym.C-Up" = "font-size:increase";
      "keysym.C-Down" = "font-size:decrease";
      "keysym.C-S-Up" = "font-size:incglobal";
      "keysym.C-S-Down" = "font-size:decglobal";
      "keysym.C-equal" = "font-size:reset";
      "keysym.C-slash" = "font-size:show";
    };
  };
}
