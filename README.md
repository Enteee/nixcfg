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

Update flake inputs:
```sh
nix flake update
```

Test build without switching:
```sh
nixos-rebuild build --flake .#puddle
```
