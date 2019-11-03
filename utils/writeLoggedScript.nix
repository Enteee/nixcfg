{ pkgs ? import <nixpkgs> {}, ... }:

let

  logger = "${pkgs.utillinux}/bin/logger";
  ts = "${pkgs.moreutils}/bin/ts";
  tee = "${pkgs.coreutils}/bin/tee";

in name : script: {
    strict ? true,
    log ? true,
    debug ? false,
    printenv ? true,
  }: let

    strictCmd = if strict then
      ''
      set -euo pipefail
      ''
    else "";

    logCmd = if log then
      ''
      exec 1> >(${tee} >(${logger} -t "${name}"))
      exec 2> >(${ts} '[stderr]' | ${tee} >(${logger} -t "${name}"))
      ''
    else "";

    debugCmd = if debug then
      ''
      set -x
      ''
    else "";

    printenvCmd = if printenv then
      ''
      echo "running: ${name}"
      env
      ''
    else "";

  in pkgs.writeShellScript name
    ''
      ${strictCmd}
      ${logCmd}
      ${debugCmd}
      ${printenvCmd}

      ${script}
    ''
