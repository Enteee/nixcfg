#!/usr/bin/env bash
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
MACHINES_DIR="${DIR}/machines"
NIX_CFG_DIR="/etc/nixos"

MACHINENAME="${1?Machinename not set}"

if [ "$EUID" -ne 0 ]; then
  echo "Must run $0 as root" >&2
  exit 1
fi

if [ ! -d "${MACHINES_DIR}/${MACHINENAME}" ]; then
  echo "Unmanaged machine: ${MACHINENAME}" >&2
  exit 1
fi

cat >"${DIR}/configuration.nix" <<EOF
import ./machines/${MACHINENAME}
EOF

ln -s "${DIR}" "${NIX_CFG_DIR}"

echo "Adding nix-channels"

nix-channel --add  https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz
nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
nix-channel --add https://github.com/rycee/home-manager/archive/master.tar.gz home-manager

nix-channel --update
