# To enable fingerprint readers, set services.fprintd.enable = true;
# Fprint makes login and other auth processes slow and clunky. Better to stick to password based login.
# https://www.reddit.com/r/Ubuntu/comments/rhi13u/comment/hot1c88/?utm_source=share&utm_medium=web2x&context=3

{ config, lib, ... }:


{
  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];

  config = lib.mkIf config.services.fprintd.enable {
    environment.persistence."/nix/state" = {
      directories = [ "/var/lib/fprint" ];
    };
  };
}
