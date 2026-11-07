{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    profiles.default = {
      userSettings = {
        telemetry.telemetryLevel = "off";
        java.home = "${pkgs.jdk}/lib/openjdk";
        python.defaultInterpreterPath = "${
          pkgs.python3.withPackages (
            ps: with ps; [
              pylint
              autopep8
            ]
          )
        }/bin/python3";
        files.exclude = {
          "**/.classpath" = true;
          "**/.project" = true;
          "**/.settings" = true;
          "**/.factorypath" = true;
        };
        cmake.configureOnOpen = true;
        editor.minimap.enabled = false;
      };

      extensions = (
        with pkgs.vscode-extensions;
        [
          ms-vscode.cpptools
          ms-vscode.cmake-tools
          xaver.clang-format

          ms-python.python
          ms-python.vscode-pylance
          mkhl.direnv

          vscjava.vscode-java-pack

          arrterian.nix-env-selector
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        ]
      );
    };
  };
}
