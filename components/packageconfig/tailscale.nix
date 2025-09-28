{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.installconfig.impermanence && config.services.tailscale.enable) {
    # https://forum.tailscale.com/t/persist-your-tailscale-darlings/904/4
    systemd.services.tailscaled.serviceConfig.BindPaths =
      "/nix/state/var/lib/tailscale:/var/lib/tailscale";

    # Ensure that /nix/state/var/lib/tailscale exists.
    systemd.tmpfiles.rules =
      [ "d /nix/state/var/lib/tailscale 0700 root root" ];
  };
}
