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
        models = "/var/lib/ollama-models";
        environmentVariables = {
          OLLAMA_CONTEXT_LENGTH="32768";
          OLLAMA_FLASH_ATTENTION="1";
          OLLAMA_KV_CACHE_TYPE="q4_0";
        };
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

    (lib.mkIf
      (
        config.services.ollama.enable
        && config.services.tailscale.enable
        && config.services.tailscale.provisionCert.enable
        && config.services.nginx.enable
      )
      {
        # Add service users to the tailscalecert group
        users.users.nginx.extraGroups = [ "tailscalecert" ];

        # Configure Nginx
        services.nginx = {
          virtualHosts."ollama-proxy" = {
            # Listen on port 11433 with SSL enabled
            listen = [
              {
                # TODO: bind only to tailscale nic
                addr = "0.0.0.0";
                port = 11433;
                ssl = true;
              }
            ];

            onlySSL = true;
            sslCertificate = certPath;
            sslCertificateKey = keyPath;

            # Route incoming 11433 requests to localhost:11434
            locations."/" = {
              proxyPass = "http://127.0.0.1:11434";
              proxyWebsockets = true;
            };
          };
        };

        # 3. Ensure Nginx depends strictly on the cert sync service
        systemd.services.nginx = {
          after = [ "tailscale-cert-sync.service" ];
          requires = [ "tailscale-cert-sync.service" ];
        };
      }
    )
  ];
}
