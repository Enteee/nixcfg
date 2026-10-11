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

The system builds purely from flake inputs; root's `nix-channel` entries are
unused for `--flake` builds. They are still what `NIX_PATH` resolves, though,
so `nix-shell -p`, `nix-build '<nixpkgs>'` and `nix-env -iA` continue to
depend on them. To drop the channels, first point `NIX_PATH` and the registry
at the flake's locked nixpkgs:

```nix
nix.registry.nixpkgs.flake = inputs.nixpkgs;
nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
```

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
