{
  config,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    ({
      services.nginx = {
        # Enable recommended security settings
        recommendedTlsSettings = true;
        recommendedProxySettings = true;
      };
    })

    (lib.mkIf
      (
        config.services.tailscale.enable
        && config.services.tailscale.provisionCert.enable
        && config.services.nginx.enable
      )
      {
        # Add service users to the tailscalecert group
        users.users.nginx.extraGroups = [ "tailscalecert" ];

        # Ensure Nginx depends strictly on the cert sync service
        systemd.services.nginx = {
          after = [ "tailscale-cert-sync.service" ];
          requires = [ "tailscale-cert-sync.service" ];
        };
      }
    )
  ];
}
