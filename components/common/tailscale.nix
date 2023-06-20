{ config, pkgs, ... }:

{
  # install Tailscale service by default. long live tailscale!
  services.tailscale.enable = true;

  # https://forum.tailscale.com/t/persist-your-tailscale-darlings/904/4
  systemd.services.tailscaled.serviceConfig.BindPaths = "/nix/state/var/lib/tailscale:/var/lib/tailscale";

  # Ensure that /nix/state/var/lib/tailscale exists.
  systemd.tmpfiles.rules = [
    "d /nix/state/var/lib/tailscale 0700 root root"
  ];
}
