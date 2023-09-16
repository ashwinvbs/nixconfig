{config, ...}:
{
  services.flatpak.enable = true;

  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];
  environment.persistence."/nix/state" = {
    directories = [
      "/var/lib/flatpak"
    ];
    users.ashwin.directories = [
      ".var/app"
    ];
  };
}
