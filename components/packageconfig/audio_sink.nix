{ config, lib, ... }:
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
  };
}
