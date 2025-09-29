{ ... }:

{
  imports = [
    ./base.nix
    ./custom_commands.nix
    ./workstation.nix

    ./hardware
    ./packageconfig
  ];
}
