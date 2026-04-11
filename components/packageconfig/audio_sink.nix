{ config, lib, pkgs, ... }:
{
  options.installconfig.enable_audio_sink = lib.mkEnableOption "Listen on network for roc audio streams";

  config = lib.mkIf config.installconfig.enable_audio_sink {
    services.pipewire = {
      enable = true;
      systemWide = true; # Handles the service user and systemd units for you
      alsa.enable = true;
      wireplumber.enable = true;

      # Inject your ROC config into the global search path
      extraConfig.pipewire."99-roc-source" = {
        "context.modules" = [
          {
            name = "libpipewire-module-roc-source";
            args = {
              "source.name" = "remote soundcard";
              "source.props.node.name" = "roc-source";
              # Might need tuning if crackling/stuttering is observed
              "sess.latency.msec" = "64";
            };
          }
        ];
      };
    };

    # Global environment variable for ease of using wpctl
    environment.variables = {
      PIPEWIRE_RUNTIME_DIR = "/run/pipewire";
    };

    # Ensure the pipewire user has a place to save settings
    # This prevents WirePlumber from complaining about missing state directories.
    systemd.services.wireplumber.serviceConfig.StateDirectory = "wireplumber";
    systemd.services.pipewire.serviceConfig.StateDirectory = "pipewire";

    # Open the ROC ports
    networking.firewall = {
      allowedTCPPorts = [
        10001
        10002
        10003
      ];
      allowedUDPPorts = [
        10001
        10002
        10003
      ];
    };

    # Ensure real-time priority works for the system-wide service
    security.rtkit.enable = true;

    # One shot service to enumerate audio hardware and set output volume to 100%
    systemd.services.pw-init-volume = {
      description = "Initialize PipeWire Volume and Hardware Enumeration";
      after = [ "wireplumber.service" ];
      wantedBy = [ "multi-user.target" ];

      # Run once, then exit
      serviceConfig = {
        Type = "oneshot";
        User = "pipewire"; # Run as the system-wide pipewire user
        Environment = "PIPEWIRE_RUNTIME_DIR=/run/pipewire";
        RemainAfterExit = true;
      };

      # 1. Wait a few seconds for hardware discovery
      # 2. Set volume to 100%
      # 3. Unmute
      script = ''
        ${pkgs.coreutils}/bin/sleep 2
        ${pkgs.wireplumber}/bin/wpctl status
        ${pkgs.coreutils}/bin/sleep 2
        ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0
        ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
      '';
    };
  };
}
