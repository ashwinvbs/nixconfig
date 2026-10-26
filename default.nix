{
  config,
  lib,
  pkgs,
  ...
}:
let
  authorizedKeys = [
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO4lFenwqE4JN51v/7H6wB/QUtiSKbC52rMEjT/zWu5+AAAACHNzaDpja2V5"
  ];
in
{
  imports = [
    ./components
    (import ./utils/adduser.nix {
      shortname = "ashwin";
      fullname = "Ashwin Balasubramaniyan";
      isAdmin = true;
    })
  ];

  config = lib.mkMerge [
    ({
      # TODO: Figure our how to move this to components.
      # For now keep here as this conflicts with test framework.
      nixpkgs.config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };

      installconfig.impermanence.enable = true;
      users.users.ashwin.openssh.authorizedKeys.keys = authorizedKeys;
      boot.initrd.network.ssh.authorizedKeys = authorizedKeys;
    })

    (lib.mkIf (config.networking.hostName == "nuc") {
      installconfig.hardware.intelgpu = true;

      environment.systemPackages = [ pkgs.goose-cli ];

      services = {
        tailscale.provisionCert.enable = true;
        code-server = {
          enable = true;
          user = "ashwin";
          group = "users";
        };
        nginx.enable = true;
      };
    })

    (lib.mkIf (config.networking.hostName == "rig") {
      installconfig = {
        hardware.amdgpu = true;
        workstationComponents = true;
      };

      nixpkgs.config.rocmSupport = true;

      services = {
        tailscale.provisionCert.enable = true;
        ollama.enable = true;
        nginx.enable = true;
      };

      # Disable sleep. Seeing some weird issues on this desktop.
      # System automatically wakes up and gets stuck in the sleep wakeup loop
      systemd.targets = {
        sleep.enable = false;
        suspend.enable = false;
        hibernate.enable = false;
        "hybrid-sleep".enable = false;
      };
      services.displayManager.gdm.autoSuspend = false;
    })

    (lib.mkIf (config.networking.hostName == "fw") {
      installconfig = {
        hardware.intelgpu = true;
        workstationComponents = true;
      };

      # From https://github.com/NixOS/nixos-hardware/blob/master/framework/12th-gen-intel/default.nix
      boot.kernelParams = [ "nvme.noacpi=1" ];
      services.udev.extraRules = ''
        SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa0e0", ATTR{power/control}="on"
      '';
      hardware.acpilight.enable = true;
    })
  ];
}
