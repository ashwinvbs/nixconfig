{ config, lib, pkgs, ... }:

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
      programs.vscode = {
        enable = true;
        package = pkgs.vscodium.fhs;
        defaultEditor = true;
      };
    })
  ];
}
