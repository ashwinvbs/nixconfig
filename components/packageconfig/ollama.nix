{
  config,
  lib,
  pkgs,
  ...
}:

let
  configDir = "/etc/ssl/tailscale";
  certPath = "${configDir}/tailscale.crt";
  keyPath = "${configDir}/tailscale.key";

  # Script to check certificate age and request a new one via tailscale cert
  fetchTailscaleCert = pkgs.writeShellScript "fetch-tailscale-cert" ''
    set -euo pipefail

    CERT="${certPath}"
    KEY="${keyPath}"
    RENEW=0

    # Ensure target directory exist
    mkdir -p "${configDir}"

    if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
      echo "Certificates missing. Acquisition required."
      RENEW=1
    else
      # Calculate age of certificate in days
      START_DATE=$(${pkgs.openssl}/bin/openssl x509 -in "$CERT" -noout -startdate | ${pkgs.coreutils}/bin/cut -d= -f2)
      START_EPOCH=$(${pkgs.coreutils}/bin/date -d "$START_DATE" +%s)
      NOW_EPOCH=$(${pkgs.coreutils}/bin/date +%s)
      AGE_DAYS=$(( (NOW_EPOCH - START_EPOCH) / 86400 ))

      echo "Current certificate age: $AGE_DAYS days."
      if [ "$AGE_DAYS" -gt 30 ]; then
        echo "Certificate is older than 30 days. Renewal required."
        RENEW=1
      fi
    fi

    if [ "$RENEW" -eq 1 ]; then
      echo "Resolving local Tailscale FQDN..."
      
      # Extract FQDN (e.g., "rig.taileb722.ts.net.") and strip the trailing dot
      TS_BIN="${config.services.tailscale.package}/bin/tailscale"
      FQDN=$($TS_BIN status --json | ${pkgs.jq}/bin/jq -r '.Self.DNSName' | sed "s/\.$//")

      if [ -z "$FQDN" ] || [ "$FQDN" = "null" ]; then
        echo "ERROR: Could not resolve Tailscale FQDN. Is tailscaled running and authenticated?" >&2
        exit 1
      fi

      echo "Requesting certificate for $FQDN..."
      if $TS_BIN cert \
        --cert-file "$CERT" \
        --key-file "$KEY" \
        "$FQDN"; then
        
        echo "Successfully updated certificates."

        # Set permissions so nginx group can read the private key
        ${pkgs.coreutils}/bin/chmod 0644 "$CERT"
        ${pkgs.coreutils}/bin/chmod 0640 "$KEY"
        ${pkgs.coreutils}/bin/chown root:nginx "$KEY"
      else
        echo "ERROR: 'tailscale cert' failed." >&2
        exit 1
      fi
    else
      echo "Certificates are valid and up to date."
    fi
  '';
in
{
  config = lib.mkMerge [
    ({
      services.ollama = {
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

    (lib.mkIf
      (config.services.ollama.enable && config.services.tailscale.enable && config.services.nginx.enable)
      {
        # offset the ollama port by one, so the regular 11434 can be used by the tls wrapped proxy
        services.ollama.port = 11433;

        systemd.services.tailscale-cert-sync = {
          description = "Check and fetch Tailscale SSL certificates";

          # 1. Wait for Tailscale network daemon and online connectivity
          after = [
            "network-online.target"
            "tailscaled.service"
          ];
          wants = [
            "network-online.target"
            "tailscaled.service"
          ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${fetchTailscaleCert}";
            RemainAfterExit = true;
          };
        };

        # Configure Nginx
        services.nginx = {
          virtualHosts."ollama-proxy" = {
            # Listen on port 11434 with SSL enabled
            listen = [
              {
                # TODO: bind only to tailscale nic
                addr = "0.0.0.0";
                port = 11434;
                ssl = true;
              }
            ];

            sslCertificate = certPath;
            sslCertificateKey = keyPath;

            # Route incoming 11434 requests to localhost:11433
            locations."/" = {
              proxyPass = "http://127.0.0.1:11433";
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
