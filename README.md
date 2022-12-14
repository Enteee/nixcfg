# nixcfg
NixOs Configuration

## Required Channels

```sh
nix-channel --add https://github.com/NixOS/nixpkgs/archive/nixos-22.11.tar.gz nixos
nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
nix-channel --add https://github.com/rycee/home-manager/archive/release-22.11.tar.gz home-manager
```

And in case you want to go super-bleeding edge:
```sh
nix-channel --add https://github.com/NixOS/nixpkgs/archive/master.tar.gz nixos
```

But I'd rather just use that for single packages
```sh
NIXPKGS_ALLOW_UNFREE=1 nix-env -f https://github.com/NixOS/nixpkgs/archive/master.tar.gz -iA steam
```

## Usage

```
./install.sh machinename
```
