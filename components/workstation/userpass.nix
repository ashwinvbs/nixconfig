{ config, lib, pkgs, ... }:

{
  users.users.ashwin.hashedPassword = lib.strings.fileContents /etc/nixos/nixconfig/secrets/ashpass.txt;
}
