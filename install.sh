#!/usr/bin/env bash
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ORIGIN_URL="$( cd "${DIR}" && git config --get remote.origin.url )"
MACHINES_DIR="${DIR}/machines"
NIX_CFG_DIR="/etc/nixos"

MACHINENAME="${1?Machinename not set}"

if [ "$EUID" -ne 0 ]; then
  echo "Must run $0 as root" >&2
  exit -1
fi

if [ ! -d "${MACHINES_DIR}/${MACHINENAME}" ]; then
  echo "Unmanaged machine: ${MACHINENAME}" >&2 && exit -1
fi

git clone \
  --quiet \
  --recursive \
  "${DIR}" "${NIX_CFG_DIR}"

git \
  -C "${NIX_CFG_DIR}" \
remote set-url \
  "origin" "${ORIGIN_URL}"

cat >"${NIX_CFG_DIR}/configuration.nix" <<EOF
import ./machines/${MACHINENAME}
EOF
