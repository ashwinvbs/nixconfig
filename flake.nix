{
  description = ''
    Unified NixOS Flake with Disko Partitioning and Impermanence

    Usage Commands:
      1. Partition & Format Drive:
         sudo nix run github:ashwinvbs/nixconfig#<host>.disko

      2. Install System:
         sudo nixos-install --flake github:ashwinvbs/nixconfig#<host>

    Available Hosts:
      - nuc
      - xps
      - rig
      - fw
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      impermanence,
      ...
    }:
    let
      authorizedKeys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO4lFenwqE4JN51v/7H6wB/QUtiSKbC52rMEjT/zWu5+AAAACHNzaDpja2V5"
      ];

      # -------------------------------------------------------------------
      # Shared Disko Partitioning Scheme matching setupfs.ts
      # -------------------------------------------------------------------
      mkDiskoConfig =
        {
          device ? "/dev/nvme0n1",
          swapSizeG ? 0,
        }:
        {
          disko.devices = {
            disk = {
              main = {
                type = "disk";
                inherit device;
                content = {
                  type = "gpt";
                  partitions = {
                    # 1. EFI Boot Partition (ef00 -> nixboot)
                    nixboot = {
                      size = "1G";
                      type = "EF00";
                      content = {
                        type = "filesystem";
                        format = "vfat";
                        mountpoint = "/boot";
                        mountOptions = [
                          "fmask=0077"
                          "dmask=0077"
                        ];
                      };
                    };

                    # 2. Optional Swap Partition (8200 -> swap)
                    swap = nixpkgs.lib.mkIf (swapSizeG > 0) {
                      size = "${toString swapSizeG}G";
                      type = "8200";
                      content = {
                        type = "swap";
                        randomEncryption = true;
                      };
                    };

                    # 3. LUKS Encrypted Store/State Partition (8300 -> nixsystem)
                    nixsystem = {
                      size = "100%";
                      type = "8300";
                      content = {
                        type = "luks";
                        name = "nixsystem";
                        settings.allowDiscards = true;
                        content = {
                          type = "filesystem";
                          format = "ext4";
                          mountpoint = "/nix";
                        };
                      };
                    };
                  };
                };
              };
            };

            # Root (/) on RAM (tmpfs) for amnesiac / impermanence setup
            nodev."/" = {
              fsType = "tmpfs";
              mountOptions = [
                "defaults"
                "size=4G"
                "mode=755"
              ];
            };
          };
        };

      # -------------------------------------------------------------------
      # Helper Function for Common System Configuration
      # -------------------------------------------------------------------
      mkHost =
        {
          hostName,
          systemModules ? [ ],
          system ? "x86_64-linux",
          diskoConfig ? { },
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            (mkDiskoConfig diskoConfig)
            (
              {
                config,
                lib,
                pkgs,
                ...
              }:
              {
                imports = [
                  ./components
                  (import ./utils/adduser.nix {
                    shortname = "ashwin";
                    fullname = "Ashwin Balasubramaniyan";
                    isAdmin = true;
                  })
                ];

                networking.hostName = hostName;

                nixpkgs.config = {
                  allowUnfree = true;
                  android_sdk.accept_license = true;
                };

                installconfig.impermanence.enable = true;
                users.users.ashwin.openssh.authorizedKeys.keys = authorizedKeys;
                boot.initrd.network.ssh.authorizedKeys = authorizedKeys;
              }
            )
          ]
          ++ systemModules;
        };

      allHosts = [
        "nuc"
        "xps"
        "rig"
        "fw"
      ];

      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      formatter.x86_64-linux = pkgs.nixfmt-tree;
      # -------------------------------------------------------------------
      # Host Configurations with Inlined Host-Specific Settings
      # -------------------------------------------------------------------
      nixosConfigurations = {
        nuc = mkHost {
          hostName = "nuc";
          systemModules = [
            {
              installconfig.hardware.intelgpu = true;
            }
          ];
        };

        xps = mkHost {
          hostName = "xps";
          systemModules = [
            {
              installconfig = {
                hardware.intelgpu = true;
                workstation_components = true;
              };
            }
          ];
        };

        rig = mkHost {
          hostName = "rig";
          systemModules = [
            {
              installconfig = {
                hardware.amdgpu = true;
                workstation_components = true;
              };
            }
          ];
        };

        fw = mkHost {
          hostName = "fw";
          diskoConfig = {
            swapSizeG = 16;
          };
          systemModules = [
            {
              installconfig = {
                hardware.intelgpu = true;
                workstation_components = true;
              };

              boot.kernelParams = [ "nvme.noacpi=1" ];
              services.udev.extraRules = ''
                SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa0e0", ATTR{power/control}="on"
              '';
              hardware.acpilight.enable = true;
            }
          ];
        };
      };

      # -------------------------------------------------------------------
      # Nested Disko App Execution Wrappers (#<host>.disko)
      # -------------------------------------------------------------------
      apps.x86_64-linux =
        (nixpkgs.lib.genAttrs allHosts (hostName: {
          disko = {
            type = "app";
            program = "${
              disko.lib.makeDiskoScript self.nixosConfigurations.${hostName}.config.disko.devices
            }/bin/disko";
          };
        }))
        // {
          default = {
            type = "app";
            program = "${nixpkgs.legacyPackages.x86_64-linux.writeShellScriptBin "install-help" ''
              echo "========================================================"
              echo " NixOS Remote Installation Workflow"
              echo "========================================================"
              echo ""
              echo "1. Run Disko partitioning and LUKS setup:"
              echo "   sudo nix run .#<host>.disko"
              echo ""
              echo "2. Install NixOS system:"
              echo "   sudo nixos-install --flake .#<host>"
              echo ""
              echo "Available hosts: ${nixpkgs.lib.concatStringsSep ", " allHosts}"
              echo "========================================================"
            ''}/bin/install-help";
          };
        };
    };
}
