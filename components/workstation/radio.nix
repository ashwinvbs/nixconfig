{ config, lib, ... }:

{
  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];

  config = lib.mkIf config.installconfig.workstation-components.enable {
    environment.persistence."/nix/state" = {
      directories = [
        "/var/lib/bluetooth"
        "/etc/NetworkManager/system-connections"
      ];
    };
  };
}
