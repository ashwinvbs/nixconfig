{ config, pkgs, ... }:

{
  ## Cleanup operations
  # Specify size constraints for nix store
  # Free upto 1G when free space falls below 100M
  nix.extraOptions = ''
    min-free = ${toString (100 * 1024 * 1024)}
    max-free = ${toString (1024 * 1024 * 1024)}
  '';

  # Clean up week old packages
  # NOTE: It is possible that too many initrd disks are created and /boot runs out of space.
  # I suspect the logs wont have any indication of the error. Newer generations would just stop appearing.
  # If this happens, start manually deleting generations.
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
}
