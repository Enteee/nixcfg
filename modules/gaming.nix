{ ... }:

# Steam and the ports its local features need.
#
# Split out because it is the one role either machine could plausibly drop:
# pond has the GPU for it, puddle does not. Both still import it today.

{
  programs.steam.enable = true;

  # Steam in-home streaming and local network discovery.
  networking.firewall.allowedUDPPortRanges = [
    {
      from = 27031;
      to = 27036;
    }
  ];
  networking.firewall.allowedTCPPorts = [ 27036 ];
}
