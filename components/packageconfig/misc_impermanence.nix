{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.installconfig.impermanence.enable ({
    # File system defines
    fileSystems."/".options = [
      "defaults"
      "size=8G"
      "mode=755"
    ];

    # Fix the file mode for /etc/machine-id.
    # Without this, impermanence sets the mode as 0644
    systemd.tmpfiles.rules = [
      # Type, Path, Mode, User, Group, Age, Argument
      "z /etc/machine-id 0444 root root -"
    ];

    environment.persistence."/nix/state" = lib.mkMerge [
      ({
        hideMounts = true;
        directories = [
          "/etc/nixos"
          "/var/lib/nixos"
        ];
        files = [ "/etc/machine-id" ];
      })

      (lib.mkIf config.installconfig.impermanence.retainLogs {
        directories = [ "/var/log" ];
      })

      (lib.mkIf config.services.fprintd.enable {
        directories = [
          {
            directory = "/var/lib/fprint";
            mode = "0700";
          }
        ];
      })

      (lib.mkIf config.services.flatpak.enable {
        directories = [ "/var/lib/flatpak" ];
      })

      (lib.mkIf config.virtualisation.docker.enable {
        directories = [ "/var/lib/docker" ];
      })

      (lib.mkIf config.hardware.bluetooth.enable {
        directories = [
          {
            directory = "/var/lib/bluetooth";
            mode = "0700";
          }
        ];
      })

      (lib.mkIf config.networking.networkmanager.enable {
        directories = [ "/etc/NetworkManager/system-connections" ];
      })
    ];
  });
}
