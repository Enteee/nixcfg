{
  nixpkgs ? import <nixpkgs> {},
  in32BitShell ? false

  /*
  nixpkgs ?  import (builtins.fetchGit {
    url = "https://github.com/nixos/nixpkgs-channels/";

    #
    # Commit hash for nixos-unstable
    # `git ls-remote https://github.com/nixos/nixpkgs-channels nixos-unstable`
    #name = "nixos-unstable-2020-07-06"; ref = "refs/heads/nixos-unstable";
    #rev = "dc80d7bc4a244120b3d766746c41c0d9c5f81dfa";

    #
    # Commit hash for nixos-20.03
    # `git ls-remote https://github.com/nixos/nixpkgs-channels nixos-20.03`
    name = "nixos-20.03-2020-07-06";
    ref = "refs/heads/nixos-20.03";
    rev = "afa9ca61924f05aacfe495a7ad0fd84709d236cc";
  }) {}
  */
}:


with nixpkgs;

let

  # use fixed python version
  python = python3;

  python-with-base-packages = python.withPackages(ps: with ps; [

    # the following packages are related to the dependencies of your python
    # project.
    # In this particular example the python modules listed in the
    # requirements.txt require the following packages to be installed locally
    # in order to compile any binary extensions they may require.
    #

    ipython

    pwntools

    # for c datatypes
    numpy

    ROPGadget

    binwalk
  ]);

  patchelf-set-interpreter = writeShellScriptBin "patchelf-set-interpreter" ''
    original_interpreter="''$(${patchelf}/bin/patchelf --print-interpreter "''${@}")"
    new_interpreter="''$(cat ''$NIX_CC/nix-support/dynamic-linker)"

    echo "Patching interpreter: ''${original_interpreter} -> ''${new_interpreter}"

    patchelf \
      --debug \
      --set-interpreter "''${new_interpreter}" \
      "''${@}"
  '';

  shell-no-aslr = writeShellScriptBin "shell-no-aslr" ''
    export SHELL_NAME="no-aslr"
    ${utillinux}/bin/setarch "''$(${coreutils}/bin/uname -m)" -R "''${SHELL}" -$-
  '';

  shell-afl = writeShellScriptBin "shell-afl" ''
    export SHELL_NAME="afl"
    export CC="${afl}/bin/afl-clang-fast"
    ''${SHELL} -$-
  '';

  shell-clang = writeShellScriptBin "shell-clang" ''
    export SHELL_NAME="clang"
    export CC="${clang}/bin/clang"
    ''${SHELL} -$-
  '';

  shell-fhs = buildFHSUserEnv {
    name = "shell-fhs";

    # binaries
    targetPkgs = pkgs: [
    ];

    # libraries
    multiPkgs = pkgs: [
    ];
  };

  shell-32bit = writeShellScriptBin "shell-32bit" (
    if in32BitShell then ''
      echo "You already are in a 32 bit shell!" >&2
      exit 1
    '' else ''
      export SHELL_NAME="32bit"
      nix-shell --expr "(import <nixpkgs> {}).callPackage_i686 ${./default.nix} {
        in32BitShell = true;
      }"
    ''
  );

  pwntools-gdb = writeShellScriptBin "pwntools-gdb" ''
    exec ${pwndbg}/bin/pwndbg "''${@}"
  '';

  pwntools-terminal = writeShellScriptBin "pwntools-terminal" ''
    ${rxvt-unicode}/bin/urxvt -e sh -c "''${@}"
  '';

  x86_64_pdf = builtins.fetchurl {
    url = "https://software.intel.com/content/dam/develop/public/us/en/documents/325462-sdm-vol-1-2abcd-3abcd.pdf";
    sha256 = "1bhdkqi7p5b702qjsiwh9xb394v44c0wlwhzls7bk8dc2ffw45ib";
  };

  doc_x86_64 = writeShellScriptBin "doc-x86_64" ''
    ${evince}/bin/evince "${x86_64_pdf}" "''${@}" &
  '';

  one_gadget_of_bin = writeShellScriptBin "one_gadget-of-bin" ''
    bin="''${1?Missing binary}" && shift
    libc="$(ldd "''${bin}" | sed -nre 's/.*libc\.so.* => (.*) \([0-9a-fx]+\)/\1/p')"
    ${one_gadget}/bin/one_gadget "''${libc}" "''${@}"
  '';

in mkShell.override {
  stdenv = multiStdenv;
}{

  buildInputs = [
    # documentation
    doc_x86_64
    manpages
    posix_man_pages

    # base devel
    binutils
    libtool
    autoconf
    automake
    pkg-config

    # common used libs
    zlib
    lzma
    ncurses
    openssl

    # Security Tools
    ghidra-bin
    hexedit

    # ROP
    one_gadget
    one_gadget_of_bin

    # build compiler database
    bear

    # fuzzing
    afl
    libcgroup

    # pwntools
    gdb
    pwndbg
    pwntools-gdb
    pwntools-terminal

    # custom shells
    shell-no-aslr
    shell-afl
    shell-clang
    shell-fhs
    shell-32bit

    # custom tools
    patchelf-set-interpreter

    # ,=e
    # `-.  No step on snek
    # _,-'
    python-with-base-packages
  ] ++ (
    # 32 bit env
    with nixpkgs.pkgsi686Linux;
    [

    ]
  );

  shellHook = ''
    '';

  venvDir = "./venv";
}
