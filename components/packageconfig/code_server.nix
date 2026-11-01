{
  config,
  lib,
  pkgs,
  ...
}:

let
  certPath = "${config.services.tailscale.provisionCert.path}/tailscale.crt";
  keyPath = "${config.services.tailscale.provisionCert.path}/tailscale.key";

  # Derived from the configured service user (see TODO below); scripts and
  # paths follow the same user so they stay consistent with upstream's
  # RuntimeDirectory/User= wiring.
  csUser = config.services.code-server.user;
  csGroup = config.services.code-server.group;
  csHome = config.users.users.${csUser}.home;
  runtimeDir = "/run/${csUser}";
  configDir = "${csHome}/.config/code-server";
  configFile = "${configDir}/config.yaml";
  welcomeFile = "${runtimeDir}/ssh-welcome";
in
{
  config = lib.mkMerge [
    (lib.mkIf (config.services.code-server.enable) {
      services.code-server = {
        # Listen only on loopback; nginx terminates TLS and proxies here.
        # The NixOS module passes --bind-addr=${host}:${port} on the command
        # line, which overrides the config.yaml below, so these must agree.
        host = "127.0.0.1";
        port = 8000;
        auth = "password";
        disableTelemetry = true;
        disableUpdateCheck = true;
      };

      systemd.services.code-server = {
        path = with pkgs; [
          coreutils
          openssl
        ];

        preStart = ''
          # Create ~/.config with restrictive permissions, matching the
          # impermanence metadata for it, even when we are the first app
          # to create it. Subsequent apps keep using it as-is.
          install -d -m 700 "${csHome}/.config"
          install -d -m 700 "${configDir}"

          # 1. Generate a random 16-character hex password
          PASSWORD=$(head -c 16 /dev/urandom | od -A n -t x1 | tr -d ' \n')

          # 2. Overwrite the config file dynamically
          cat <<EOF > "${configFile}"
          bind-addr: 127.0.0.1:8000
          auth: password
          password: $PASSWORD
          cert: false
          disable-telemetry: true
          disable-update-check: true
          EOF

          chown -R ${csUser}:${csGroup} "${configDir}"
          chmod 600 "${configFile}"

          # 3. Write the banner to the directory NixOS already created for us (${runtimeDir})
          echo -e "\n\033[1;34m====================================================\033[0m" > "${welcomeFile}"
          echo -e "\033[1;32m🚀 code-server IDE is ready!\033[0m" >> "${welcomeFile}"
          echo -e "\033[1;37mURL:      http://${config.networking.hostName}:8000\033[0m" >> "${welcomeFile}"
          echo -e "\033[1;37mPassword: $PASSWORD\033[0m" >> "${welcomeFile}"
          echo -e "\033[1;34m====================================================\033[0m\n" >> "${welcomeFile}"
        '';
      };

      environment.interactiveShellInit = ''
        if [ "$USER" = "${csUser}" ] && [ -f "${welcomeFile}" ]; then
          cat "${welcomeFile}"
        fi
      '';
    })

    (lib.mkIf
      (
        config.services.code-server.enable
        && config.services.tailscale.enable
        && config.services.tailscale.provisionCert.enable
        && config.services.nginx.enable
      )
      {
        # Configure Nginx
        services.nginx = {
          virtualHosts."code-server-proxy" = {
            listen = [
              {
                # TODO: bind only to tailscale nic
                addr = "0.0.0.0";
                port = 443;
                ssl = true;
              }
            ];

            default = true;
            onlySSL = true;
            sslCertificate = certPath;
            sslCertificateKey = keyPath;

            # Route incoming 11433 requests to localhost:11434
            locations."/" = {
              proxyPass = "http://127.0.0.1:8000";
              proxyWebsockets = true;
            };
          };
        };
      }
    )
  ];
}
