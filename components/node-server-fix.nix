# From https://github.com/microsoft/vscode-remote-release/issues/103#issuecomment-1060907227
{ config, pkgs, ... }:

let
  fix_node_server = pkgs.writeScriptBin "fix_node_server" ''
      #! /usr/bin/env bash

      set u+
      for node in "$HOME"/.vscode-server/bin/*/node
      do
        if "$node" --version; then
          echo "Node is working"
        else
          echo "Needs fixing..."
          mv "$node" "$node.backup"
          ln -s "/run/current-system/sw/bin/node" "$node"
          if "$node" --version; then
            echo  "Fixed: Node is now working"
          fi
        fi
      done
  '';

in
{
  environment.systemPackages = [ 
    pkgs.nodejs-16_x
    fix_node_server
  ];
}
