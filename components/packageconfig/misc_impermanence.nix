{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.installconfig.impermanence ({
    # File system defines
    fileSystems."/".options = [ "defaults" "size=2G" "mode=755" ];

    environment.persistence."/nix/state" = lib.mkMerge [
      ({
        hideMounts = true;
        directories = [ "/etc/nixos" "/var/lib/nixos" "/var/log" ];
        files = [ "/etc/machine-id" ];
      })

      (lib.mkIf config.virtualisation.libvirtd.enable {
        directories = [ "/var/lib/libvirt" ];
      })

      (lib.mkIf config.services.fprintd.enable {
        directories = [ "/var/lib/fprint" ];
      })

      (lib.mkIf config.services.flatpak.enable {
        directories = [ "/var/lib/flatpak" ];
      })

      (lib.mkIf config.virtualisation.docker.enable {
        directories = [ "/var/lib/docker" ];
      })

      (lib.mkIf config.hardware.bluetooth.enable {
        directories = [ "/var/lib/bluetooth" ];
      })

      (lib.mkIf config.networking.networkmanager.enable {
        directories = [ "/etc/NetworkManager/system-connections" ];
      })
    ];
  });
}
