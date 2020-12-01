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
  pythonPackages = python37Packages;

  python-with-base-packages = python.withPackages(ps: with ps; [

    # the following packages are related to the dependencies of your python
    # project.
    # In this particular example the python modules listed in the
    # requirements.txt require the following packages to be installed locally
    # in order to compile any binary extensions they may require.
    #

  ]);

in mkShell.override {
  stdenv = multiStdenv;
}{

  buildInputs = [
    # ,=e
    # `-.  No step on snek
    # _,-'
    python-with-base-packages

    # Triggers the .venv after entering the shell.
    pythonPackages.venvShellHook
  ];

  shellHook = ''
    '';

  postShellHook = ''
    pip install -r requirements.txt
  '';

  venvDir = "./venv";
}
