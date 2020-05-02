# nixcfg
NixOs Configuration

## Required Channels

```sh
nix-channel --add https://nixos.org/channels/nixos-unstable
nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
nix-channel --add https://github.com/rycee/home-manager/archive/master.tar.gz home-manager
```

And in case you want to go super-bleeding edge:
```sh
nix-channel --add https://github.com/NixOS/nixpkgs/archive/master.tar.gz nixos
```

## Usage

```
./install.sh machinename
```
