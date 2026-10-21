{
  config,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    (lib.mkIf (config.services.coder.enable && config.installconfig.impermanence.enable) {
      environment.persistence."/nix/state".directories = [
        {
          directory = config.services.coder.homeDir;
          user = config.services.coder.user;
          group = config.services.coder.group;
          mode = "0700";
        }
      ];
    })

    (lib.mkIf
      (
        config.services.coder.enable
        && config.services.tailscale.enable
        && config.services.tailscale.provisionCert.enable
      )
      {
        # Add service users to the tailscalecert group
        users.users.coder.extraGroups = [ "tailscalecert" ];

        services.coder = {
          tlsKey = "${config.services.tailscale.provisionCert.path}/tailscale.key";
          tlsCert = "${config.services.tailscale.provisionCert.path}/tailscale.crt";
          # accessUrl = "https://nuc.taileb722.ts.net";
          listenAddress = "0.0.0.0:443";
        };
      }
    )
  ];
}
