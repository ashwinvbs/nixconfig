# To execute test, use the following command: nix-build ./test_impermanence.nix
# Ref: https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html

let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-26.05";
  pkgs = import nixpkgs {
    config.allowUnfree = true;
    overlays = [ ];
  };
in
pkgs.testers.runNixOSTest {
  name = "Impermanence Test";
  nodes = {
    machine = import ./testvm.nix;
    reference =
      { lib, pkgs, ... }:
      {
        imports = [ ./testvm.nix ];
        environment.systemPackages = [
          pkgs.zip
          pkgs.android-tools
        ];
        installconfig.impermanence.enable = lib.mkForce false;
        systemd.services.bluetooth.unitConfig.ConditionPathIsDirectory = lib.mkForce "";
      };
  };
  testScript = ''
    machine.wait_for_file("/run/user/1000/bus")
    reference.wait_for_file("/run/user/1000/bus")

    # Ensure /etc/machine-id is not empty on both machines
    machine.succeed("test -s /etc/machine-id")
    reference.succeed("test -s /etc/machine-id")

    # Programmatically trigger/seed the directories that depend on binary execution
    # (Run dummy commands or initializations as the test user)
    reference.succeed("su - testuser -c 'rustup --version'")
    reference.succeed("su - testuser -c 'ssh-keygen -t rsa -b 2048 -N \"\" -f ~/.ssh/id_rsa -q'")
    reference.succeed(r"""
      su - testuser -c '
        set -e
        mkdir -p /tmp/dud-ext/extension
        printf "{\"name\":\"dud-ext\",\"publisher\":\"test\",\"version\":\"0.0.1\",\"engines\":{\"vscode\":\"^1.0.0\"}}" > /tmp/dud-ext/extension/package.json
        cd /tmp/dud-ext
        zip -r /tmp/dud.vsix extension
        codium --install-extension /tmp/dud.vsix
      '
    """)

    # TODO: check if this is necessary
    reference.succeed("systemctl start bluetooth.service fprintd.service")

    # /home/testuser/.android : created by adb (ANDROID_HOME per devtools.nix) on first use.
    reference.succeed("su - testuser -c 'adb start-server'")
    reference.succeed("su - testuser -c 'adb kill-server'")

    # /var/lib/ollama-models : owned by the ollama service (services.ollama.models).
    # This is a one-off hack. If we use a custom path, ollama service does not create this dir and fails to start.
    # The default path, is managed by systemd and we cannot use impermanence to persist subdirs, hence the catch-22.
    reference.succeed("install -dm 700 -o ollama -g ollama /var/lib/ollama-models")

    # /var/lib/flatpak : system-wide flatpak install root, initialized by the flatpak client.
    reference.succeed("flatpak --system remote-list")

    # /home/testuser/.var/app : flatpak per-app data dir. Created by flatpak itself
    # via flatpak_ensure_data_dir (the same code path flatpak run uses) when an app
    # build is bound to its app home (--with-appdir). Only the build scaffold under
    # /tmp is created here; ~/.var/app comes from the flatpak tooling.
    reference.succeed(r"""
      su - testuser -c '
        set -e
        mkdir -p /tmp/appseed/files /tmp/appseed/usr/bin
        printf "[Application]\nname=org.test.Appseed\nruntime=org.test.Rt/x86_64/1.0\nsdk=org.test.Sdk/x86_64/1.0\ncommand=x\n" > /tmp/appseed/metadata
        true_bind=$(readlink "$(type -P true)")
        flatpak build --with-appdir --bind-mount=/nix/store=/nix/store /tmp/appseed "$true_bind"
        test -d ~/.var/app
      '
    """)

    machine.succeed("sleep 5")
    reference.succeed("sleep 5")

    file_list = machine.succeed("systemctl show '*.mount' -p Where --value | sort | awk 'NF' | grep -E '^(/home/|/etc/|/var/)'")

    # Dump the actual directory permissions.
    machine.succeed(
        "cat << 'EOF' > /tmp/file_list.txt\n"
        f"{file_list}"
        "EOF"
    )
    actual_permissions = machine.succeed("cat /tmp/file_list.txt | xargs -L1 stat -c '%n %U:%G:%A' | sort")

    # Dump the reference directory permissions.
    reference.succeed(
        "cat << 'EOF' > /tmp/file_list.txt\n"
        f"{file_list}"
        "EOF"
    )
    reference_permissions = reference.succeed("cat /tmp/file_list.txt | xargs -L1 stat -c '%n %U:%G:%A' | sort")

    actual_lines = actual_permissions.strip().splitlines()
    reference_lines = reference_permissions.strip().splitlines()

    mismatches = 0
    for act, ref in zip(actual_lines, reference_lines):
        if act != ref:
            print(f"MISMATCH:\n  Actual:    {act}\n  Reference: {ref}")
            mismatches += 1

    if len(actual_lines) != len(reference_lines):
        print(f"Line count mismatch: Actual has {len(actual_lines)} lines, Reference has {len(reference_lines)} lines.")
        mismatches += abs(len(actual_lines) - len(reference_lines))

    assert mismatches == 0, f"Found {mismatches} permission or ownership mismatch(es)!"
  '';
}
