{ config, pkgs, ... }:

let
  impermanence = builtins.fetchTarball {
    url =
      "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  };
in {
  fileSystems."/".options = [ "defaults" "size=2G" "mode=755" ];
  fileSystems."/state".neededForBoot = true;

  imports = [ "${impermanence}/nixos.nix" ];
  environment.persistence."/state" = {
    directories = [
      "/home"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
