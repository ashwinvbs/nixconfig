{ config, lib, pkgs, ... }:

{
  config = lib.mkMerge [
    ({
      services.ollama = {
        user = "ollama";
        group = "ollama";
        models = "/var/lib/ollama-models";
      };
    })

    (lib.mkIf (config.services.ollama.enable && config.installconfig.impermanence.enable) {
      environment.persistence."/nix/state".directories = [{
        directory = config.services.ollama.models;
        user = config.services.ollama.user;
        group = config.services.ollama.group;
      }];
    })
  ];
}
