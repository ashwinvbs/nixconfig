{ config, pkgs, ... }:

{
  # install Tailscale service by default. long live tailscale!
  services.tailscale.enable = true;

  # https://forum.tailscale.com/t/persist-your-tailscale-darlings/904/4
  systemd.services.tailscaled.serviceConfig.BindPaths = "/state/var/lib/tailscale:/var/lib/tailscale";
}