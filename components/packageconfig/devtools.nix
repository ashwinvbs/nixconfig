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
      environment.systemPackages = with pkgs; [
        (vscode-with-extensions.override {
          vscode = vscodium;
          vscodeExtensions = (
            [
              vscode-extensions.alefragnani.bookmarks
            ] ++ vscode-utils.extensionsFromVscodeMarketplace [{
              name = "gitstash";
              publisher = "arturock";
              version = "5.2.0";
              sha256 = "sha256-IVWb4tXD+5YbqJv4Ajp0c3UvYdMzh83NlyiYpndclEY=";
            }]
          ) ++ lib.optionals config.installconfig.devtools (
            [
              vscode-extensions.denoland.vscode-deno
              vscode-extensions.jnoortheen.nix-ide
              vscode-extensions.rust-lang.rust-analyzer
              vscode-extensions.vadimcn.vscode-lldb
              vscode-extensions.llvm-vs-code-extensions.vscode-clangd
            ] ++ vscode-utils.extensionsFromVscodeMarketplace [{
              name = "geminicodeassist";
              publisher = "Google";
              version = "2.37.0";
              sha256 = "sha256-oJmWxdEN2uTo5Ms3WFrTbosd+DKQq4jrOtPChQjaWe0=";
            }]
          );
        })
      ];
    })
  ];
}
