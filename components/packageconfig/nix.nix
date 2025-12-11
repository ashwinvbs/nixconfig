{ config, lib, pkgs, ... }:

{
  config = {
    programs.command-not-found.enable = true;
    environment.sessionVariables = {
      # Make running non installed commands interactive and painless
      NIX_AUTO_RUN = 1;
      NIX_AUTO_RUN_INTERACTIVE = 1;
    };

    nix = {
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
  };
}
