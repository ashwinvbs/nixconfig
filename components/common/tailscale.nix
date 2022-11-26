{ config, pkgs, ... }:

let
  impermanence = builtins.fetchTarball {
    url =
      "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  };
in {
  # install Tailscale service by default. long live tailscale!
  services.tailscale.enable = true;

  imports = [ "${impermanence}/nixos.nix" ];
  environment.persistence."/state" = {
    files = [
      "/var/lib/tailscale"
    ];
  };
}