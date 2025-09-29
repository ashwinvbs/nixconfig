{ config, lib, pkgs, ... }:
let
  updatescript = pkgs.writeShellScriptBin "nixos-update"
    "nixos-rebuild boot --upgrade --option tarball-ttl 10";
  upgradescript = pkgs.writeShellScriptBin "nixos-upgrade-branch"
    "nix-channel --add https://channels.nixos.org/nixos-$1 nixos";
  reboottofirmware = pkgs.writeShellScriptBin "reboot-to-firmware"
    "systemctl reboot --firmware-setup";
  debugkernelinterrupts = pkgs.writeShellScriptBin "debug-kernel-interrupts"
    "watch -n0.1 -d --no-title cat /proc/interrupts";
in
{
  config.environment.systemPackages = with pkgs; [
    updatescript
    upgradescript
    debugkernelinterrupts
    reboottofirmware
  ];
}
