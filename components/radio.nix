{ ... }:

let
  impermanence = builtins.fetchTarball {
    url =
      "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  };
in {
  imports = [ "${impermanence}/nixos.nix" ];
  environment.persistence."/state" = {
    directories = [
      "/var/lib/bluetooth"
      "/etc/NetworkManager/system-connections"
    ];
  };
}
