# Ashwin's Nixos configuration.
## Installation instructions
* Run `setupfs` script with the following args to setup file system for nixos.
* Install using command `setupnixos`
* Upgrade with `sudo nixos-rebuild boot --upgrade --option tarball-ttl 0`
### Upgrading branches.
* nix-channel --add https://channels.nixos.org/nixos-<version\> nixos
* nixos-rebuild as usual
