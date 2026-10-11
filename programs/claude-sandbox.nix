{ pkgs, lib, ... }:

let
  bwrap = lib.getExe pkgs.bubblewrap;

  # Core tools guaranteed to exist inside the sandbox regardless of what the
  # user profile happens to contain. The profile dirs are appended below for
  # convenience; they are all store paths, so they leak nothing.
  corePath = lib.makeBinPath (with pkgs; [
    claude-code
    bashInteractive
    coreutils
    findutils
    diffutils
    gnugrep
    gnused
    gawk
    gnutar
    gzip
    git
    ripgrep
    jq
    curl
    less
    which
  ]);

  # /etc and /run/current-system are bind-mounted read-only, so the regular
  # NixOS profile bin dirs still resolve inside the sandbox.
  sandboxPath = "${corePath}:/etc/profiles/per-user/ente/bin:/run/current-system/sw/bin";

  # Validates the cwd and prepares sandbox-local state. Sets $boxDir, $creds
  # and $project, which runSandboxed below expects.
  preamble = ''
    # Sandbox-local Claude state. Deliberately not ~/.claude: the sandbox gets
    # its own history/settings and never sees the real config tree.
    boxDir="$HOME/.claude-box"
    mkdir -p "$boxDir/config"
    [ -e "$boxDir/claude.json" ] || printf '{}' > "$boxDir/claude.json"

    # The OAuth token is the one real secret the sandbox needs. Bound
    # read-write because Claude rewrites it on token refresh.
    creds="$HOME/.claude/.credentials.json"
    if [ ! -e "$creds" ]; then
      echo "''${0##*/}: $creds not found. Run 'claude' once unsandboxed to log in." >&2
      exit 1
    fi

    project="$PWD"
    if [ "$project" = "$HOME" ]; then
      echo "''${0##*/}: refusing to run directly in \$HOME; that would expose everything." >&2
      exit 1
    fi
  '';

  # dev.tty.legacy_tiocsti is 0 on this kernel, so terminal injection is
  # already blocked and --new-session can be omitted. Omitting it keeps the
  # controlling terminal attached, which interactive TUIs need for Ctrl-C.
  #
  # Only $project is writable. $HOME is a tmpfs, so ~/.ssh, ~/.gnupg, ~/.kube,
  # ~/.npmrc, ~/.pgpass and friends are simply not there. /run/user is a tmpfs
  # too, which keeps the D-Bus and SSH agent sockets out.
  runSandboxed = ''
    runSandboxed() {
      exec ${bwrap} \
        --die-with-parent \
        --unshare-all \
        --share-net \
        --clearenv \
        --ro-bind /nix/store /nix/store \
        --ro-bind /etc /etc \
        --ro-bind /bin /bin \
        --ro-bind /usr /usr \
        --ro-bind /run/current-system /run/current-system \
        --proc /proc \
        --dev /dev \
        --tmpfs /tmp \
        --tmpfs "/run/user/$(id -u)" \
        --tmpfs "$HOME" \
        --bind "$boxDir/config" "$HOME/.claude" \
        --bind "$boxDir/claude.json" "$HOME/.claude.json" \
        --bind "$creds" "$HOME/.claude/.credentials.json" \
        --ro-bind-try "$HOME/.config/git" "$HOME/.config/git" \
        --bind "$project" "$project" \
        --chdir "$project" \
        --setenv HOME "$HOME" \
        --setenv USER "$USER" \
        --setenv SHELL "${lib.getExe pkgs.bashInteractive}" \
        --setenv PATH "${sandboxPath}" \
        --setenv TERM "''${TERM:-xterm-256color}" \
        --setenv LANG "''${LANG:-C.UTF-8}" \
        --setenv COLORTERM "''${COLORTERM:-truecolor}" \
        --setenv XDG_RUNTIME_DIR "/run/user/$(id -u)" \
        -- "$@"
    }
  '';

  claude-box = pkgs.writeShellApplication {
    name = "claude-box";
    text = preamble + runSandboxed + ''
      runSandboxed claude "$@"
    '';
  };

  # Same sandbox, arbitrary command. With no arguments it drops into a shell,
  # which is the quickest way to inspect what the sandbox actually exposes.
  box = pkgs.writeShellApplication {
    name = "box";
    text = preamble + runSandboxed + ''
      if [ "$#" -eq 0 ]; then
        set -- bash
      fi

      runSandboxed "$@"
    '';
  };
in
{
  home.packages = [ claude-box box ];
}
