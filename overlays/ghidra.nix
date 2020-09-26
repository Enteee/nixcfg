#
# Increase ghidra ui size for HIDPI
#
self: super: {
  ghidra-bin = (super.ghidra-bin.overrideAttrs (oldAttrs: {
    postFixup = ''
      ${oldAttrs.postFixup}
      sed -r -i -e \
        's/VMARGS_LINUX=-Dsun.java2d.uiScale=1/VMARGS_LINUX=-Dsun.java2d.uiScale=2/g' \
        $out/lib/ghidra/support/launch.properties
      '';
  }));
}
