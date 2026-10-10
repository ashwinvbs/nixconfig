{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Script to check certificate age and request a new one via tailscale cert
  fetchTailscaleCert = pkgs.writeShellScript "fetch-tailscale-cert" ''
    set -euo pipefail

    CERT="${config.services.tailscale.provisionCert.path}/tailscale.crt"
    KEY="${config.services.tailscale.provisionCert.path}/tailscale.key"
    RENEW=0

    # Ensure target directory exist
    mkdir -p "${config.services.tailscale.provisionCert.path}"

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

      # Extract FQDN (e.g., "host.tailnet.ts.net.") and strip the trailing dot
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
        ${pkgs.coreutils}/bin/chown root:tailscalecert "$KEY"
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
  options.services.tailscale.provisionCert = {
    enable = lib.mkEnableOption "Enable certificate provisioning. Note that HTTPS Certificats have to be enabled in the Tailscale console first.";
    path = lib.mkOption {
      type = lib.types.str;
      default = "/etc/ssl/tailscale";
      description = "The path where the provisioned tailscale key and cert files are stored.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (config.installconfig.impermanence.enable && config.services.tailscale.enable) {
      # https://forum.tailscale.com/t/persist-your-tailscale-darlings/904/4
      systemd.services.tailscaled.serviceConfig.BindPaths =
        "/nix/state/var/lib/tailscale:/var/lib/tailscale";

      # Ensure that /nix/state/var/lib/tailscale exists.
      systemd.tmpfiles.rules = [ "d /nix/state/var/lib/tailscale 0700 root root" ];
    })

    (lib.mkIf (config.services.tailscale.enable && config.services.tailscale.provisionCert.enable) {
      # Utility group for controlling read access to tailscale certificates.
      users.groups.tailscalecert = { };

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
        };
      };

      systemd.timers.tailscale-cert-sync = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "10m";
          OnUnitActiveSec = "10d";
          Unit = "tailscale-cert-sync.service";
        };
      };
    })

    (lib.mkIf
      (
        config.installconfig.impermanence.enable
        && config.services.tailscale.enable
        && config.services.tailscale.provisionCert.enable
      )
      {
        environment.persistence."/nix/state".directories = [
          config.services.tailscale.provisionCert.path
        ];
      }
    )
  ];
}
