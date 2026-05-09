{
  config,
  pkgs,
  ...
}:
let
  # Upgrade scripts
  updatescript = pkgs.writeShellScriptBin "nixos-update" "nixos-rebuild boot --upgrade --option tarball-ttl 10";
  upgradescript = pkgs.writeShellScriptBin "nixos-upgrade-branch" "nix-channel --add https://channels.nixos.org/nixos-$1 nixos";
  # Other utility scripts
  reboottofirmware = pkgs.writeShellScriptBin "reboot-to-firmware" "systemctl reboot --firmware-setup";
  debugkernelinterrupts = pkgs.writeShellScriptBin "debug-kernel-interrupts" "watch -n0.1 -d --no-title cat /proc/interrupts";
  # SSh utilities
  sshforward = pkgs.writeShellScriptBin "ssh-forward" "exec ssh -NL \"$2:localhost:$2\" \"$1\"";
  sshkeepalive = pkgs.writeShellScriptBin "ssh-keepalive" "exec ssh -t \"$1\" \"systemd-inhibit --why='Remote SSH session' --what='sleep:idle' bash\"";
in
{
  config.environment.systemPackages = with pkgs; [
    updatescript
    upgradescript
    debugkernelinterrupts
    reboottofirmware
    sshforward
    sshkeepalive
  ];
}
