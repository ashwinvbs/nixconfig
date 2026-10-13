# Ashwin's NixOS configuration

My personal, modular NixOS system configuration, plus an installer image and
standalone embedded/SBC (Raspberry Pi, PinePhone) images.

See [`AGENTS.md`](./AGENTS.md) for the repository map, the module conventions, and
all build/test harnesses — this file only covers user-facing install and
maintenance.

## Requirements

- NixOS with `nix-command` and `flakes` enabled (the config enables these system-wide).
- A NixOS installer environment (for installs) — see `installer/`.
- Deno, for `installer/setupfs.ts` (pinned via `deno.json` / `deno.lock`).

## Installation

1. Boot the installer image and run the `setupfs` command to prepare the filesystem.
   The ISO's `setupfs` is the bash script `installer/setupfs.sh`:
   - `setupfs -d|--disk /dev/<disk> -m|--machine <hostname> -e|--encryption plain|password`
   - A newer Deno variant, `installer/setupfs.ts`, instead takes `--disk`, `--machine`,
     `--swapsize`, and `--encrypt`/`--no-encrypt`.
2. Install the system with:
   - `setupnixos` (which runs `nixos-install --no-root-passwd`).
3. Add additional user passwords with `mkpasswd -m sha-512 > <file>` under
   `/etc/nixos/secrets/`.

## System maintenance

Commands available on configured hosts (defined in `components/customcommands/`):

- `nixos-update` — rebuild/flip to the next boot generation with fresh tarballs
  (`nixos-rebuild boot --upgrade --option tarball-ttl 10`).
- `nixos-upgrade-branch <version>` — point the `nixos` channel at a new release
  (e.g. `24.11`, `unstable`).
- `reboot-to-firmware` — reboot straight into firmware setup.
- `ssh-forward <host> <port>`, `ssh-keepalive <host>`, `debug-kernel-interrupts`.

`reboot-to-firmware`, `nixos-update`, and `nixos-upgrade-branch` affect the running
system — double-check before using them.

## License

Personal configuration; no license file is currently provided.
