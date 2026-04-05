{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.installconfig.impermanence.enable && config.services.tailscale.enable) {
    # https://forum.tailscale.com/t/persist-your-tailscale-darlings/904/4
    systemd.services.tailscaled.serviceConfig.BindPaths =
      "/nix/state/var/lib/tailscale:/var/lib/tailscale";

    # Ensure that /nix/state/var/lib/tailscale exists.
    systemd.tmpfiles.rules =
      [ "d /nix/state/var/lib/tailscale 0700 root root" ];

    # Configure blocky to resolve Tailscale names by forwarding to Tailscale's IP
    services.blocky.settings.conditional.mapping = {
      "ts.net" = "100.100.100.100";
    };
  };
}
