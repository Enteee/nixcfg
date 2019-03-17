#!/usr/bin/env bash
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
MACHINES_DIR="${DIR}/machines"
NIX_CFG_DIR="/etc/nixos"

HOSTNAME="${1?Hostname not set}"

if [ "$EUID" -ne 0 ]; then
  echo "Must run $0 as root" >&2
  exit -1
fi

if [ ! -d "${MACHINES_DIR}/${HOSTNAME}" ]; then
  echo "Unmanaged host: ${HOSTNAME}" >&2 && exit -1
fi

git clone \
  --quiet \
  --recursive \
  "${DIR}" "${NIX_CFG_DIR}"

cat >"${NIX_CFG_DIR}/configuration.nix" <<EOF
import ./machines/${HOSTNAME}
EOF
