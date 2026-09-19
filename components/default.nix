{ ... }:

{
  imports = [
    ./base.nix
    ./workstation.nix

    ./customcommands
    ./hardware
    ./packageconfig
  ];
}
