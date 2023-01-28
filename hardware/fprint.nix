{ ... }:

# Fprint makes login and other auth processes slow and clunky. Better to stick to password based login.
# https://www.reddit.com/r/Ubuntu/comments/rhi13u/comment/hot1c88/?utm_source=share&utm_medium=web2x&context=3

let
  impermanence = builtins.fetchTarball {
    url =
      "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  };
in {
  imports = [ "${impermanence}/nixos.nix" ];
  environment.persistence."/state" = {
    directories = [
      "/var/lib/fprint"
    ];
  };

  services.fprintd.enable = true;
}
