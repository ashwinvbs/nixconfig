{ lib, ... }:

{
  imports = [
    # ./common/autoupdate.nix
    ./common/base.nix
    ./common/nix-gc.nix
    ./common/programs.nix
    ./common/ssh-host.nix
    ./common/tailscale.nix
    ./common/users.nix

    ./workstation/auto-timezone.nix
    ./workstation/chromium.nix
    ./workstation/gnome.nix
    ./workstation/keychron-fix.nix
  ];

  options.installconfig.components.workstation = lib.mkEnableOption "Configure the machine to be a workstation";
}
