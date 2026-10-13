# AGENTS.md

Guidance for AI coding agents (and humans) working in this repository. This file is
tool-agnostic and is loaded automatically by agents that understand `AGENTS.md`.

## What this repo is

A modular **NixOS system configuration** for personal machines, plus an installer
image and standalone embedded/SBC images. It is *not* an application codebase:
"source" is Nix modules, and the main "build" is evaluating/rebuilding a NixOS system.

Intent: keep per-feature configuration small and composable, toggled through a shared
`installconfig.*` option namespace, and pin host behavior by `networking.hostName`.

Read [`README.md`](./README.md) for the user-facing install/maintenance instructions.

## Repository map

| Path | What it is / when you touch it |
| --- | --- |
| `default.nix` | Root module. Imports `./components` + `utils/adduser.nix`; applies host-specific overrides keyed on `networking.hostName`. |
| `components/default.nix` | Aggregates `base.nix`, `workstation.nix`, `customcommands/`, `hardware/`, `packageconfig/`. **Register new component dirs here.** |
| `components/base.nix` | Baseline system: boot, `resolved` DNS, timezone, `autoUpgrade`, openssh, tailscale, git, tmux, `mutableUsers = false`. |
| `components/workstation.nix` | Desktop extras behind `installconfig.workstation_components` (GNOME, flatpak, chromium, graphics, qmk, steam-hw, spice). |
| `components/hardware/` | GPU drivers, `fwupd`, `fstrim`, swap, EFI config, printing/scanning. Registered in `components/hardware/default.nix`. |
| `components/packageconfig/` | One module per service/tool area (git, nix, gnome, firefox, chromium, tailscale, ollama, libvirt, waydroid, nginx, sudo, ...). Registered in `components/packageconfig/default.nix`. |
| `components/customcommands/` | Defines custom CLI commands (`nixos-update`, `nixos-upgrade-branch`, `ssh-forward`, `ssh-keepalive`, `reboot-to-firmware`, `debug-kernel-interrupts`, `test-nixconfig`). |
| `components/test/` | VM-based tests: `test.nix` (integration test) and `sanity.nix` (a full test host config). |
| `utils/adduser.nix` | Declares a user + impermanence persistence + admin groups. Import it with an attrset, e.g. `(import ./utils/adduser.nix { shortname = "ashwin"; isAdmin = true; })`. |
| `utils/addmicrovm.nix` | Declares a `microvm.nix` host-scoped guest; import with `{ vmname, ncpu, memsize, ... }`. |
| `installer/` | `installer-image.nix` builds the install ISO; `setupfs.sh` (bash) and `setupfs.ts` (Deno) are the filesystem setup scripts. |
| `embedded/raspi4/`, `embedded/pinephone/` | Standalone flakes for SBC targets. |
| `flake.nix` | Provides only a `formatter` (`nixfmt-tree`). **No `nixosConfigurations` output.** |

## How a host is assembled

1. On an installed machine, `/etc/nixos/configuration.nix` does
   `builtins.fetchGit { url = ".../nixconfig.git"; ref = "main"; }` and imports it.
2. That resolves to `default.nix`, which imports `components/` and `utils/adduser.nix`.
3. `components/default.nix` pulls in base/workstation/customcommands/hardware/packageconfig.
4. Host differences are selected by `networking.hostName` (see below); feature toggles
   come from `installconfig.*`.

Known hostnames used in `default.nix`:

| `networking.hostName` | Applied config |
| --- | --- |
| `nuc` | `installconfig.hardware.intelgpu` |
| `rig` | `installconfig.hardware.amdgpu` + `installconfig.workstation_components` |
| `fw` | `installconfig.hardware.intelgpu` + `installconfig.workstation_components` (Framework kernel params, `acpilight`) |
| `testing` | Test host, defined in `components/test/sanity.nix` |

## The component convention (important)

Every feature module follows the same shape:

```nix
{ config, lib, pkgs, ... }:
{
  options.installconfig.<feature> = lib.mkEnableOption "short description";

  config = lib.mkIf config.installconfig.<feature> {
    # actual NixOS config
  };
}
```

Rules and conventions:

- **Always gate feature config behind an `installconfig.*` option**; rarely enable
  things unconditionally. Use `lib.mkIf` for one toggle and `lib.mkMerge` when a module
  reacts to several (see `components/packageconfig/devtools.nix`,
  `misc_impermanence.nix`).
- Use `lib.mkDefault` / `lib.mkForce` deliberately when another layer may also set the
  same option (see `base.nix`, `workstation.nix`).
- **Register the module** by adding its path to the `imports` list in the relevant
  `default.nix` (e.g. `components/packageconfig/default.nix`). A module that is not
  imported does nothing.

### Full list of `installconfig.*` options

| Option | Module |
| --- | --- |
| `installconfig.workstation_components` | `components/workstation.nix` |
| `installconfig.impermanence.enable` | `components/packageconfig/default.nix` |
| `installconfig.impermanence.retainLogs` | `components/packageconfig/default.nix` |
| `installconfig.hardware.intelgpu` | `components/hardware/intelgpu.nix` |
| `installconfig.hardware.amdgpu` | `components/hardware/amdgpu.nix` |
| `installconfig.devtools` | `components/packageconfig/devtools.nix` |
| `installconfig.godotdev` | `components/packageconfig/devtools.nix` |
| `installconfig.enable_audio_sink` | `components/packageconfig/audio_sink.nix` |
| `installconfig.enable_virtual_camera` | `components/packageconfig/virtual_camera.nix` |

Note: naming is inconsistent — some options are grouped under `hardware.`, others are
flat and snake_cased. Match the surrounding file's style; don't rename existing options
without updating `default.nix`, `sanity.nix`, and the embedded flakes that reference them.

## Common tasks

- **Format (do this before committing):** `nix fmt` (uses `nixfmt-tree`).
- **Add a service/tool:** create `components/packageconfig/<name>.nix` in the module
  shape above and add it to `components/packageconfig/default.nix`.
- **Add hardware support:** create `components/hardware/<name>.nix` and add it to
  `components/hardware/default.nix`.
- **Add a host:** add a `lib.mkIf (config.networking.hostName == "<name>") { ... }` block
  in `default.nix`, and set `networking.hostName` in the generated `configuration.nix`.
- **Add a custom command:** add a `pkgs.writeShellApplication` in
  `components/customcommands/default.nix` and include it in `environment.systemPackages`.

## Build / test harnesses

| Harness | Command | Notes |
| --- | --- | --- |
| Format | `nix fmt` | `nixfmt-tree` from `flake.nix`. |
| Quick VM | `test-nixconfig [path]` | Builds and runs a throwaway VM from a config file or a dir containing `default.nix` (defaults to `.`). |
| Integration test | `nix-build ./components/test/test.nix` | `runNixOSTest`; expects `google-chrome-stable`. Pins nixpkgs `nixos-26.05`. |
| Sanity VM | `nix-build '<nixpkgs/nixos>' -A vm -I nixpkgs=channel:nixos-26.05 -I nixos-config=./components/test/sanity.nix` | Boots the full config with most `installconfig.*` toggles on. |
| Installer ISO | `nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=installer/installer-image.nix` | Produces the install medium. |
| Embedded images | `nix build ./embedded/raspi4` (and `./embedded/pinephone`) | Independent flakes; `pinephone` also exposes a `nix run ./embedded/pinephone#vm` app. |

Maintenance commands available on configured hosts: `nixos-update`,
`nixos-upgrade-branch <version>`, `reboot-to-firmware`, `ssh-forward`, `ssh-keepalive`,
`debug-kernel-interrupts`.

## Gotchas

- **No flake for the system.** The root `flake.nix` only ships a formatter. There is no
  `nixosConfigurations`, so `nixos-rebuild switch --flake .#host` is not the workflow;
  hosts consume this repo via `builtins.fetchGit` from a generated `configuration.nix`.
- **Channels, not lockfiles, drive hosts.** Test/embedded targets pin specific nixpkgs
  releases (e.g. `nixos-26.05`), while host updates flow through channels +
  `system.autoUpgrade`.
- **`users.mutableUsers = false`** (`base.nix`). User passwords come from
  `/etc/nixos/secrets/<passprefix>_pass.txt` (see `utils/adduser.nix`); interactive
  `passwd` changes will not persist.
- **Impermanence.** Root is a tmpfs (`size=8G`) when `installconfig.impermanence.enable`
  is set; persistent state lives under `/nix/state`. Anything that must survive a reboot
  (service state dirs, user files) must be added to `environment.persistence."/nix/state"`.
- **Secrets** live in `/etc/nixos/secrets/`, which `setupfs` symlinks into the
  persistence store. Do not commit secrets or authoring SSH keys.
- `nixpkgs.config.allowUnfree` and `android_sdk.accept_license` are set directly in
  `default.nix` (not in a component) because they conflict with the test framework.

## Safety / do-not

- Do not modify `authorizedKeys` or anything under `/etc/nixos/secrets`.
- Treat `reboot-to-firmware`, `nixos-update`, and `nixos-upgrade-branch` as
  system-affecting: confirm before running them, and never run them as part of a
  change whose intent you have not verified.
- Prefer changing the source here and rebuilding over editing live system files.
- Keep `.gitignore` files (`components/test/`, `embedded/`) in mind; build artifacts
  (`result`, `*.qcow2`) should not be committed.
