{
  config,
  lib,
  ...
}:

let
  certPath = "${config.services.tailscale.provisionCert.path}/tailscale.crt";
  keyPath = "${config.services.tailscale.provisionCert.path}/tailscale.key";
in
{
  config = lib.mkMerge [
    ({
      services.ollama = {
        user = "ollama";
        group = "ollama";
        # The default path is managed by service, so we cant bind mount into it.
        models = "/var/lib/ollama-models";
        environmentVariables = {
          OLLAMA_CONTEXT_LENGTH = "32768";
          OLLAMA_FLASH_ATTENTION = "1";
          OLLAMA_KV_CACHE_TYPE = "q4_0";
        };
      };
    })

    (lib.mkIf (config.services.ollama.enable && config.installconfig.impermanence.enable) {
      environment.persistence."/nix/state".directories = [
        {
          directory = config.services.ollama.models;
          user = config.services.ollama.user;
          group = config.services.ollama.group;
          mode = "0700";
        }
      ];
    })

    (lib.mkIf
      (
        config.services.ollama.enable
        && config.services.tailscale.enable
        && config.services.tailscale.provisionCert.enable
        && config.services.nginx.enable
      )
      {
        # Configure Nginx
        services.nginx = {
          virtualHosts."ollama-proxy" = {
            listen = [
              {
                # TODO: bind only to tailscale nic
                addr = "0.0.0.0";
                port = 11433;
                ssl = true;
              }
            ];

            default = true;
            onlySSL = true;
            sslCertificate = certPath;
            sslCertificateKey = keyPath;

            # Route incoming 11433 requests to localhost:11434
            locations."/" = {
              proxyPass = "http://127.0.0.1:11434";
              proxyWebsockets = true;
              extraConfig = ''
                proxy_set_header Host localhost:11434;
              '';
            };
          };
        };
      }
    )
  ];
}
