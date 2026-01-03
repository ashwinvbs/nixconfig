{ config, lib, pkgs, ... }:

{
  config = lib.mkMerge [
    ({
      virtualisation.libvirtd.qemu.swtpm.enable = true;
    })

    (lib.mkIf (config.virtualisation.libvirtd.enable && config.installconfig.impermanence.enable) {
      environment.persistence."/nix/state".directories = [ "/var/lib/libvirt" ];
    })
  ];
}
