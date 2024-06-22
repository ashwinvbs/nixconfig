{ lib, ... }:

{
  imports = [
    ./workstation/auto-timezone.nix
    ./workstation/chromium.nix
    ./workstation/gnome.nix
    ./workstation/keychron-fix.nix
  ];

  options.installconfig.components.workstation = lib.mkEnableOption "Configure the machine to be a workstation";
}
