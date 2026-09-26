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
      # -------------------------------------------------------------------
      # Shared Disko Partitioning Scheme matching setupfs.ts
      # -------------------------------------------------------------------
      mkDiskoConfig =
        {
          device ? "/dev/nvme0n1",
          withSwap ? false,
          swapSizeG ? 16,
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
                    swap = nixpkgs.lib.mkIf withSwap {
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

      # Helper function to construct host outputs cleanly
      mkHost =
        {
          hostName,
          system ? "x86_64-linux",
          device ? "/dev/nvme0n1",
          withSwap ? false,
          swapSizeG ? 16,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
            ./default.nix
            (mkDiskoConfig { inherit device withSwap swapSizeG; })
            {
              networking.hostName = hostName;
            }
          ];
        };

      hosts = [
        "nuc"
        "xps"
        "rig"
      ];

      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      formatter.x86_64-linux = pkgs.nixfmt-tree;
      # 1. Standard NixOS host configurations
      nixosConfigurations = {
        nuc = mkHost { hostName = "nuc"; };
        xps = mkHost { hostName = "xps"; };
        rig = mkHost { hostName = "rig"; };
        fw = mkHost {
          hostName = "fw";
          withSwap = true;
          swapSizeG = 16;
        };
      };

      # 2. Nested Disko Apps mapped per host
      apps.x86_64-linux = nixpkgs.lib.genAttrs (hosts ++ [ "fw" ]) (hostName: {
        disko = {
          type = "app";
          program = "${
            disko.lib.makeDiskoScript self.nixosConfigurations.${hostName}.config.disko.devices
          }/bin/disko";
        };
      });
    };
}
