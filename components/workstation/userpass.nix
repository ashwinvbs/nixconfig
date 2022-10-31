{ config, lib, pkgs, ... }:

{
  users.users.ashwin.hashedPassword = lib.strings.fileContents /etc/nixos/secrets/ashpass.txt;
}
