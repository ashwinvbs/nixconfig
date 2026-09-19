{
  config,
  pkgs,
  ...
}:
let
  # Upgrade scripts
  nixos-update = pkgs.writeShellApplication {
    name = "nixos-update";
    runtimeInputs = [ pkgs.nixos-rebuild ];
    text = ''
      nixos-rebuild boot --upgrade --option tarball-ttl 10
    '';
  };

  nixos-upgrade-branch = pkgs.writeShellApplication {
    name = "nixos-upgrade-branch";
    runtimeInputs = [ pkgs.nix ];
    text = ''
      if [ -z "''${1:-}" ]; then
        echo "Error: Please specify a channel release (e.g., 24.11 or unstable)" >&2
        exit 1
      fi
      nix-channel --add "https://channels.nixos.org/nixos-$1" nixos
    '';
  };

  # Other utility scripts
  reboot-to-firmware = pkgs.writeShellApplication {
    name = "reboot-to-firmware";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      systemctl reboot --firmware-setup
    '';
  };

  debug-kernel-interrupts = pkgs.writeShellApplication {
    name = "debug-kernel-interrupts";
    runtimeInputs = [
      pkgs.procps
      pkgs.coreutils
    ];
    text = ''
      watch -n0.1 -d --no-title cat /proc/interrupts
    '';
  };

  # SSH utilities
  ssh-forward = pkgs.writeShellApplication {
    name = "ssh-forward";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      if [ "$#" -lt 2 ]; then
        echo "Usage: ssh-forward <host> <port>" >&2
        exit 1
      fi
      exec ssh -NL "$2:localhost:$2" "$1"
    '';
  };

  ssh-keepalive = pkgs.writeShellApplication {
    name = "ssh-keepalive";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      if [ "$#" -lt 1 ]; then
        echo "Usage: ssh-keepalive <host>" >&2
        exit 1
      fi
      exec ssh -t "$1" "systemd-inhibit --why='Remote SSH session' --what='sleep:idle' bash"
    '';
  };
  # Script to spin up a quick vm based on config passed in args
  test-nixconfig = pkgs.writeShellApplication {
    name = "test-nixconfig";
    runtimeInputs = [ ];
    text = builtins.readFile ./test-nixconfig.sh;
  };
in
{
  config.environment.systemPackages = with pkgs; [
    nixos-update
    nixos-upgrade-branch
    debug-kernel-interrupts
    reboot-to-firmware
    ssh-forward
    ssh-keepalive
    test-nixconfig
  ];
}
