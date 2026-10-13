# nixcfg
NixOs Configuration

## Machines

- **puddle** — Lenovo ThinkPad T480s (daily driver)
- **pond** — Desktop with NVIDIA GPU

## Usage

Build and switch:
```sh
sudo nixos-rebuild switch --flake .#puddle
sudo nixos-rebuild switch --flake .#pond
```

Test build without switching:
```sh
nixos-rebuild build --flake .#puddle
```

## Updating

Inputs are recorded in `flake.lock`. The URLs in `flake.nix` point at
*branches* (`nixos-26.05`), not fixed commits, so updating means moving the
lock forward to the branch tip — the flake equivalent of `nix-channel
--update`.

```sh
nix flake update                              # all inputs
nix flake update nixpkgs                      # a single input
sudo nixos-rebuild switch --flake .#puddle
git commit flake.lock -m "flake update"
```

Commit `flake.lock`. That is the whole point of the lock: a bad update is
`git revert` plus a rebuild, instead of guesswork about which revision the
channel happened to be on.

Coming from channels:

| task | channels | flakes |
| --- | --- | --- |
| pull new nixpkgs | `sudo nix-channel --update` | `nix flake update` |
| rebuild | `sudo nixos-rebuild switch` | `sudo nixos-rebuild switch --flake .#puddle` |
| update + rebuild | `nixos-rebuild switch --upgrade` | both commands above |

`nixos-rebuild --upgrade` has no effect on this config — it updates channels,
which a `--flake` build ignores.

### Release upgrades

Edit `flake.nix`, bumping both inputs together:

- `nixpkgs`: `nixos-26.05` → `nixos-26.11`
- `home-manager`: `release-26.05` → `release-26.11`

Then `nix flake update` and switch. Expect renamed or removed options; build
each machine before switching and fix what the evaluation warnings name.

Leave `system.stateVersion` and `home.stateVersion` alone — they pin
stateful defaults to the release the machine was installed with, and are not
version markers to bump.

### Rollback

```sh
sudo nixos-rebuild switch --rollback   # previous generation
```

Or pick an older generation in the boot menu, or `git revert` the commit that
changed `flake.lock` and rebuild.

## Channels

Disabled — `nix.channel.enable = false` in `modules/basesystem.nix`.

The system builds from `flake.lock`, and a flake-built NixOS already points
`NIX_PATH` and the flake registry at its own locked nixpkgs
(`nixpkgs.flake.setNixPath` and `setFlakeRegistry`, both on by default). So the
non-flake commands keep working and resolve to the revision the system was
built from, with no channel involved:

```sh
nix-instantiate --find-file nixpkgs   # a /nix/store path, not a channel
nix-shell -p python3
nix build nixpkgs#hello
```

The old `nixpkgs-unstable` channel had exactly one consumer, `nix-build
'<nixpkgs-unstable>' -A devenv`, from before devenv was in stable. It is in
stable now (2.1.2) and installed declaratively in `users/ente.nix`, so nothing
needs unstable. If that changes, add it as a flake input and a registry entry
rather than a channel, so it is pinned in `flake.lock`:

```nix
# flake.nix
nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

# a module, with inputs in scope
nix.registry.nixpkgs-unstable.flake = inputs.nixpkgs-unstable;
```

Then `nix build nixpkgs-unstable#foo`. Note that pinning it this way puts the
unstable sources (~200 MiB) into the system closure.

With channels off, `nix-channel` is removed from the system and `NIX_PATH` is
just `nixpkgs=flake:nixpkgs`.

### Removing the state

`nix.channel.enable = false` does not delete anything; activation only warns.
The warning is worth acting on, because a leftover channels directory is still
consulted when `NIX_PATH` is unset ([nix#9574](https://github.com/NixOS/nix/issues/9574)).
Unsubscribe before switching, while the command still exists:

```sh
for c in nixos nixpkgs-unstable nixos-hardware home-manager; do
  sudo nix-channel --remove "$c"
done
sudo rm -f /root/.nix-channels
sudo rm -rf /root/.nix-defexpr
sudo rm -rf /nix/var/nix/profiles/per-user/root/channels*
rm -rf ~/.nix-defexpr
```

The channel tarballs stay in the store until the next GC; removing the profile
links is what makes them collectable.

## Sandboxed CLI (`claude-box` / `box`)

`programs/claude-sandbox.nix` provides two wrappers that run a command in a
bubblewrap sandbox scoped to the current directory:

```sh
cd ~/some/project
claude-box          # Claude Code, sandboxed
box                 # interactive shell in the same sandbox
box cargo test      # any command in the same sandbox
```

No per-project setup: the sandbox is built from `$PWD` at launch.

What the sandbox sees:

| path | access |
| --- | --- |
| `$PWD` | read-write — the only writable host path |
| `/nix/store`, `/etc`, `/bin`, `/usr`, `/run/current-system` | read-only |
| `$HOME` | empty tmpfs; `~/.ssh`, `~/.gnupg`, `~/.pgpass`, `~/.npmrc`, `~/.kube` are absent |
| `~/.claude` | sandbox-local state from `~/.claude-box/`, plus the real OAuth token |
| `/run/user/$UID` | empty tmpfs — no D-Bus, no SSH agent socket |
| everything else | not mounted |

The environment is wiped (`--clearenv`) and rebuilt from a fixed list, so
tokens held in env vars do not cross the boundary. The Docker socket is
deliberately not bound: `ente` is in the `docker` group, which is
root-equivalent, and binding it would void the whole sandbox.

Writes outside `$PWD` land in an ephemeral tmpfs and vanish on exit. The Nix
daemon socket is unreachable, so `nix` inside the sandbox cannot mutate the
store.

Caveats:

- The OAuth token *is* exposed — the CLI cannot authenticate without it.
- Network egress is unrestricted. Filesystem isolation limits what can be
  read, not where it can be sent; add a netns egress allowlist if that
  matters.
- Same kernel as the host, so a kernel LPE escapes. Use a VM for untrusted
  code.
- No SSH agent means no `git push` from inside. Review and push from outside.

First run needs `claude` logged in on the host, so that
`~/.claude/.credentials.json` exists.
