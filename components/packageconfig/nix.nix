{ config, lib, pkgs, ... }:

{
  config.nix = lib.mkIf config.nix.enable {
    ## Cleanup operations
    # Specify size constraints for nix store in terms of main partition free space
    # Free upto 4G when free space falls below 1G
    extraOptions = ''
      min-free = ${toString (1 * 1024 * 1024 * 1024)}
      max-free = ${toString (4 * 1024 * 1024 * 1024)}
    '';

    # Clean up 2 day old packages. We can afford short cleanup duration as we rely on daily updates
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 2d";
    };

    # Enable flakes system-wide
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
}
