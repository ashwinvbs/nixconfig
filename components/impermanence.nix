# To enable docker, set virtualisation.libvirtd.enable = true;

{ config, lib, ... }:

{
  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];

  options.installconfig.enable_impermanence = lib.mkEnableOption "Enable impermanence";

  config = lib.mkIf config.installconfig.enable_impermanence ( lib.mkMerge [
    ( {
      # File system defines
      fileSystems."/".options = [ "defaults" "size=2G" "mode=755" ];

      environment.persistence."/nix/state" = lib.mkMerge [
        ( {
          hideMounts = true;
          directories = [
            "/etc/nixos"
            "/var/log"
          ];
          files = [
            "/etc/machine-id"
          ];
        } )

        ( lib.mkIf config.virtualisation.libvirtd.enable {
          directories = [ "/var/lib/libvirt" ];
        } )

        ( lib.mkIf config.services.fprintd.enable {
          directories = [ "/var/lib/fprint" ];
        } )

        ( lib.mkIf config.services.flatpak.enable {
          directories = [ "/var/lib/flatpak" ];
        } )

        ( lib.mkIf config.virtualisation.docker.enable {
          directories = [ "/var/lib/docker" ];
        } )

        ( lib.mkIf config.hardware.bluetooth.enable {
          directories = [ "/var/lib/bluetooth" ];
        } )

        ( lib.mkIf config.networking.networkmanager.enable {
          directories = [ "/etc/NetworkManager/system-connections" ];
        } )

        ( lib.mkIf config.services.openssh.enable {
          files = [
            "/etc/ssh/ssh_host_rsa_key"
            "/etc/ssh/ssh_host_rsa_key.pub"
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_ed25519_key.pub"
          ];
        } )
      ];
    } )

    ( lib.mkIf config.services.tailscale.enable {
      # https://forum.tailscale.com/t/persist-your-tailscale-darlings/904/4
      systemd.services.tailscaled.serviceConfig.BindPaths = "/nix/state/var/lib/tailscale:/var/lib/tailscale";

      # Ensure that /nix/state/var/lib/tailscale exists.
      systemd.tmpfiles.rules = [
        "d /nix/state/var/lib/tailscale 0700 root root"
      ];
    } )
  ] );
}
