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

**This file must accurately reflect the design of the repository.** After any
refactor to the repository, update `AGENTS.md` to reflect the refactor (if necessary).

## Repository map

| Path | What it is / when you touch it |
| --- | --- |
| `default.nix` | Root module. Imports `./components` + `utils/adduser.nix`; applies host-specific overrides keyed on `networking.hostName`. |
| `components/default.nix` | Aggregates `base.nix`, `workstation.nix`, `customcommands/`, `hardware/`, `packageconfig/`. **Register new component dirs here.** |
| `components/base.nix` | Baseline system: boot, `resolved` DNS, timezone, `autoUpgrade`, openssh, tailscale, git, tmux, `mutableUsers = false`. |
| `components/workstation.nix` | Desktop extras behind `installconfig.workstationComponents` (GNOME, flatpak, chromium, graphics, qmk, steam-hw, spice). |
| `components/hardware/` | GPU drivers (`gpu.nix`: `installconfig.hardware.{intelgpu,amdgpu}`), `fwupd`, `fstrim`, swap, host-platform config (`hostplatform.nix`: EFI boot, aarch64 binfmt emulation on x86_64), printing/scanning. Registered in `components/hardware/default.nix`. |
| `components/packageconfig/` | One module per service/tool area (git, nix, gnome, firefox, chromium, tailscale, ollama, libvirt, waydroid, nginx, sudo, ...). Registered in `components/packageconfig/default.nix`. |
| `components/customcommands/` | Defines custom CLI commands (`nixos-update`, `nixos-upgrade-branch`, `ssh-forward`, `ssh-keepalive`, `reboot-to-firmware`, `debug-kernel-interrupts`, `test-nixconfig`, `fw-setchargelimit`). |
| `components/test/` | VM-based tests: `test_sanity.nix`, `test_impermanence.nix`, `testvm.nix` (a full test host config). |
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
| `rig` | `installconfig.hardware.amdgpu` + `installconfig.workstationComponents` |
| `fw` | `installconfig.hardware.intelgpu` + `installconfig.workstationComponents` (Framework kernel params, `acpilight`) |
| `testing` | Test host, defined in `components/test/testvm.nix` |

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
| `installconfig.workstationComponents` | `components/workstation.nix` |
| `installconfig.impermanence.enable` | `components/packageconfig/default.nix` |
| `installconfig.impermanence.retainLogs` | `components/packageconfig/default.nix` |
| `installconfig.hardware.intelgpu` | `components/hardware/gpu.nix` |
| `installconfig.hardware.amdgpu` | `components/hardware/gpu.nix` |
| `installconfig.devtools` | `components/packageconfig/devtools.nix` |
| `installconfig.godotdev` | `components/packageconfig/devtools.nix` |
| `installconfig.enableAudioSink` | `components/packageconfig/audio_sink.nix` |
| `installconfig.enableVirtualCamera` | `components/packageconfig/virtual_camera.nix` |

Style: option names are **camelCase** (no underscores), matching upstream NixOS
conventions; brand/acronym tokens stay lowercase and unsplit (`devtools`, `godotdev`,
`intelgpu`, `amdgpu`, mirroring upstream `hardware.amdgpu`). Grouping is still split:
GPU options live under `installconfig.hardware.*`, everything else is flat. Don't rename
options without updating every call site — `default.nix`, `components/test/testvm.nix`,
and the embedded flakes (`embedded/raspi4/flake.nix` uses `enableAudioSink`).

## Common tasks

- **Format (do this before committing):** `nix fmt` (uses `nixfmt-tree`).
- **Validate (mandatory for agents):** any diff implemented by an agent has to be
  validated by running the tests (`nix-build ./components/test/test_*.nix`) — see
  Build / test harnesses below.
- **Add a service/tool:** create `components/packageconfig/<name>.nix` in the module
  shape above and add it to `components/packageconfig/default.nix`.
- **Add hardware support:** create `components/hardware/<name>.nix` and add it to
  `components/hardware/default.nix`.
- **Add a host:** add a `lib.mkIf (config.networking.hostName == "<name>") { ... }` block
  in `default.nix`, and set `networking.hostName` in the generated `configuration.nix`.
- **Add a custom command:** add a `pkgs.writeShellApplication` in
  `components/customcommands/default.nix` and include it in `environment.systemPackages`.

## Build / test harnesses

**Any diff implemented by an agent must be validated by running the tests.** Do not
stop at `nix-instantiate --parse` or an eval check — run the relevant harness(es)
below (typically `test_sanity.nix` and `test_impermanence.nix`) and confirm they pass
before the change is considered complete.

| Harness | Command | Notes |
| --- | --- | --- |
| Format | `nix fmt` | `nixfmt-tree` from `flake.nix`. |
| Quick VM | `test-nixconfig [path]` | Builds and runs a throwaway VM from a config file or a dir containing `default.nix` (defaults to `.`). |
| Sanity Test | `nix-build ./components/test/test_sanity.nix` | `runNixOSTest`; expects `google-chrome-stable`. Pins nixpkgs `nixos-26.05`. |
| Impermanence Test | `nix-build ./components/test/test_impermanence.nix` | `runNixOSTest`; two nodes (impermanence on vs off); asserts owner/group/mode of every persisted directory match. On the reference node each directory must be created by its owning service/client app (`mkdir` forbidden). Pins nixpkgs `nixos-26.05`. |
| Base VM for test | `nix-build '<nixpkgs/nixos>' -A vm -I nixpkgs=channel:nixos-26.05 -I nixos-config=./components/test/testvm.nix` | Boots the full config with all `installconfig.*` toggles on (see the coverage contract below). |
| Installer ISO | `nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=installer/installer-image.nix` | Produces the install medium. |
| Embedded images | `nix build ./embedded/raspi4` (and `./embedded/pinephone`) | Independent flakes; `pinephone` also exposes a `nix run ./embedded/pinephone#vm` app. |

### `components/test/testvm.nix` — coverage contract

`testvm.nix` exists to give **full code coverage of everything under `./components`**:
it must enable *every* `installconfig.*` option and turn on every upstream option that
gates component config (e.g. `services.printing`, `hardware.sane`,
`virtualisation.waydroid`, `networking.networkmanager`), so that each module's
`lib.mkIf` branch is actually evaluated. **When you add a component, option, or
`lib.mkIf` gate, add the matching toggle to `testvm.nix` in the same change** — an
un-toggled branch is untested config.

Deliberately untested (documented exceptions):

- **ssh-in-initrd is not tested** — `boot.initrd.network.ssh.enable` is *not* set, because
  enabling it forces `networking.networkmanager.enable = lib.mkForce false`
  (see `components/packageconfig/initrd_ssh.nix`). **NetworkManager coverage is
  prioritized over ssh-in-initrd.** Thus `initrd_ssh.nix` is only exercised by a host
  that actually enables initrd SSH (no current machine does).
- **`!installconfig.workstationComponents` branches** (`autoupgrade.nix`, and the
  `code-server` arm of `devtools.nix`) and the `networking.hostName`-specific blocks in
  `default.nix` (`nuc`/`rig`/`fw`) cannot both be covered by a single test host, since
  `testvm.nix` pins `workstationComponents = true` and `hostName = "testing"`.

Maintenance commands available on configured hosts: `nixos-update`,
`nixos-upgrade-branch <version>`, `reboot-to-firmware`, `ssh-forward`, `ssh-keepalive`,
`debug-kernel-interrupts`, `fw-setchargelimit`.

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
