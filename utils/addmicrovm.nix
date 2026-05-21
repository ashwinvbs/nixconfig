# Intended use is
# imports = [(import addmicrovm.nix {vmname = "my-vm"; ncpu = 4; memsize = 4096;})]

{
  vmname,
  autostart ? true,
  ncpu ? 8,
  memsize ? 2048 * 4,
  host_only_network ? true,
  isolate_store ? true,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # This module provides the 'services.microvm' options to the host system
    "${
      builtins.fetchTarball {
        url = "https://github.com/astro/microvm.nix/archive/main.tar.gz";
      }
    }/nixos-modules/host"
  ];

  config = {
    microvm.vms."${vmname}" = {
      autostart = autostart;

      config = {
        imports = [
          # Import your base system configuration into the VM guest
          ../default.nix
        ];

        microvm = lib.mkMerge [
          ({
            vcpu = ncpu;
            mem = memsize;
            hypervisor = "qemu";
          })

          (lib.mkIf host_only_network {
            # network configuration. host only
            interfaces = [
              {
                type = "user";
                id = "qemu-net";
              }
            ];
            qemu.extraArgs = [
              "-netdev user,id=qemu-net,restrict=yes,hostfwd=tcp::2222-:22"
            ];
          })

          (lib.mkIf isolate_store {
            volumes = [
              {
                image = "agent-store.img";
                mountPoint = "/nix";
                size = 1024 * 4; # 4GB for its own isolated store/packages
              }
            ];
            writableStore = true;
          })

          (lib.mkIf (!isolate_store) {
            shares = [
              {
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
                tag = "ro-store";
                proto = "virtiofs";
              }
            ];
          })

          # 3. Controlled Workspace Access
          # Map ONLY the project directory you want the agent to touch
          # microvm.shares = [
          #   {
          #     source = "/home/user/projects/agent-work"; # Update to your path
          #     mountPoint = "/workspace";
          #     tag = "workspace";
          #     proto = "virtiofs";
          #   }
          # ];
        ];
      };
    };
  };
}
