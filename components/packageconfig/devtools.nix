{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.installconfig = {
    devtools = lib.mkEnableOption "Tools for development";
    godotdev = lib.mkEnableOption "Tools for godot app development";
  };

  config = lib.mkMerge [
    (lib.mkIf config.installconfig.devtools {
      environment.systemPackages = with pkgs; [
        clang
        clang-tools
        deno
        gtest
        meson
        ninja
        pkg-config
        rustup
      ];
    })

    (lib.mkIf config.installconfig.godotdev {
      environment = {
        sessionVariables = rec {
          # This dir should be added to permanence
          ANDROID_HOME = "$HOME/.android";
        };
        systemPackages = with pkgs; [
          godot
          sdkmanager
        ];
      };

      programs.java = {
        enable = true;
        package = pkgs.jdk17;
      };
    })

    # TODO: Make this configurable
    (lib.mkIf config.installconfig.workstation_components {
      # IDE configuration
      environment.systemPackages = with pkgs; [ vscodium.fhs ];
      programs.bash.shellAliases.code = "codium";
    })

    # TODO: make this user independent.
    (lib.mkIf (!config.installconfig.workstation_components) {
      services.code-server = {
        enable = true;
        user = "ashwin";
        group = "users";
        host = "0.0.0.0";
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
          mkdir -p /home/ashwin/.config/code-server

          # 1. Generate a random 16-character hex password
          PASSWORD=$(head -c 16 /dev/urandom | od -A n -t x1 | tr -d ' \n')

          # 2. Overwrite the config file dynamically
          cat <<EOF > /home/ashwin/.config/code-server/config.yaml
          bind-addr: 0.0.0.0:8000
          auth: password
          password: $PASSWORD
          cert: true
          EOF

          chown -R ashwin:users /home/ashwin/.config/code-server
          chmod 600 /home/ashwin/.config/code-server/config.yaml

          # 3. Write the banner to the directory NixOS already created for us (/run/ashwin)
          echo -e "\n\033[1;34m====================================================\033[0m" > /run/ashwin/ssh-welcome
          echo -e "\033[1;32m🚀 code-server IDE is ready!\033[0m" >> /run/ashwin/ssh-welcome
          echo -e "\033[1;37mURL:      http://${config.networking.hostName}:8000\033[0m" >> /run/ashwin/ssh-welcome
          echo -e "\033[1;37mPassword: $PASSWORD\033[0m" >> /run/ashwin/ssh-welcome
          echo -e "\033[1;34m====================================================\033[0m\n" >> /run/ashwin/ssh-welcome
        '';
      };

      environment.interactiveShellInit = ''
        if [ -f /run/ashwin/ssh-welcome ]; then
          cat /run/ashwin/ssh-welcome
        fi
      '';

    })
  ];
}
