{
  config,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    ({
      services.ollama = {
        host = "0.0.0.0";
        user = "ollama";
        group = "ollama";
        models = "/var/lib/ollama-models";
        environmentVariables.OLLAMA_CONTEXT_LENGTH = "32768";
      };
    })

    (lib.mkIf (config.services.ollama.enable && config.installconfig.impermanence.enable) {
      environment.persistence."/nix/state".directories = [
        {
          directory = config.services.ollama.models;
          user = config.services.ollama.user;
          group = config.services.ollama.group;
        }
      ];
    })
  ];
}
