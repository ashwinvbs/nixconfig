{
  description = "nixos configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      lib = pkgs.lib;
      
      # Define the configuration for different hosts
      makeConfiguration = hostname: 
        let
          hostConfig = 
            lib.mkMerge [
              {
                # Common configuration
                nixpkgs.config = {
                  allowUnfree = true;
                  android_sdk.accept_license = true;
                };

                installconfig.impermanence.enable = true;
                
                users.users.ashwin.openssh.authorizedKeys.keys = [
                  "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO4lFenwqE4JN51v/7H6wB/QUtiSKbC52rMEjT/zWu5+AAAACHNzaDpja2V5"
                ];
                
                boot.initrd.network.ssh.authorizedKeys = [
                  "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO4lFenwqE4JN51v/7H6wB/QUtiSKbC52rMEjT/zWu5+AAAACHNzaDpja2V5"
                ];
              }
              
              # Host-specific configurations
              (lib.mkIf (hostname == "nuc") {
                installconfig.hardware.intelgpu = true;
              })
              
              (lib.mkIf (hostname == "xps") {
                installconfig = {
                  hardware.intelgpu = true;
                  workstation_components = true;
                };
              })
              
              (lib.mkIf (hostname == "rig") {
                installconfig = {
                  hardware.amdgpu = true;
                  workstation_components = true;
                };
              })
              
              (lib.mkIf (hostname == "fw") {
                installconfig = {
                  hardware.intelgpu = true;
                  workstation_components = true;
                };

                # TODO: Use swapdisk allocated install-time
                swapDevices = [
                  {
                    device = "/nix/swapfile";
                    size = 1024 * 16;
                    randomEncryption.enable = true;
                  }
                ];

                # From https://github.com/NixOS/nixos-hardware/blob/master/framework/12th-gen-intel/default.nix
                boot.kernelParams = [ "nvme.noacpi=1" ];
                services.udev.extraRules = ''
                  SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa0e0", ATTR{power/control}="on"
                '';
                hardware.acpilight.enable = true;
              })
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

          config = hostConfig;
        };

      # Create system configurations for different hosts
      nucConfig = makeConfiguration "nuc";
      xpsConfig = makeConfiguration "xps";
      rigConfig = makeConfiguration "rig";
      fwConfig = makeConfiguration "fw";

      # Define the default system configuration
      defaultSystem = {
        nixosConfigurations = {
          nuc = pkgs.nixos.lib.nixosSystem {
            modules = [ nucConfig ];
          };
          
          xps = pkgs.nixos.lib.nixosSystem {
            modules = [ xpsConfig ];
          };
          
          rig = pkgs.nixos.lib.nixosSystem {
            modules = [ rigConfig ];
          };
          
          fw = pkgs.nixos.lib.nixosSystem {
            modules = [ fwConfig ];
          };
        };
      };
    in
    {
      formatter.x86_64-linux = pkgs.nixfmt-rfc-style;
      
      # Export the system configurations
      nixosConfigurations = defaultSystem.nixosConfigurations;
    };
}
