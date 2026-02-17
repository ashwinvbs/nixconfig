#!/usr/bin/env nix-shell
/*
#!nix-shell -i "deno run --allow-all" -p deno
*/

import $ from "jsr:@david/dax";
import { parseArgs } from "jsr:@std/cli/parse-args";
import { promptSecret } from "jsr:@std/cli";

// Utils
let throbber_message = "";
function start_throbber() {
    let i = 0;
    const frames = [
        "⡇ ",
        "⠏ ",
        "⠋⠁",
        "⠉⠉",
        "⠈⠙",
        " ⠹",
        " ⢸",
        " ⣰",
        "⢀⣠",
        "⣀⣀",
        "⣄⡀",
        "⣆ ",
    ];
    return setInterval(() => {
        Deno.stdout.writeSync(
            new TextEncoder().encode(`\r${frames[i]} ${throbber_message}...`),
        );
        i = (i + 1) % frames.length;
    }, 100); // 80ms is a standard smooth rate
}

function sleep(s: number) {
    return new Promise((resolve) => setTimeout(resolve, s * 1000));
}

async function check_block_device(path: string, timeout: number = 0) {
    const start_timer = Date.now();
    await $`partprobe`.noThrow().quiet();

    const timeout_check = async () => {
        if (Date.now() - start_timer > timeout * 1000) {
            throw new Error(`Timed out waiting for block device ${path}`);
        }
        await sleep(0.5);
    };

    while (true) {
        try {
            const realpath = await Deno.realPath(path);
            if (Deno.statSync(realpath).isBlockDevice) return;
        } catch (err) {
            if (!(err instanceof Deno.errors.NotFound)) throw err;
        }
        await timeout_check();
    }
}

// Installer steps
async function prepare_fake_root() {
    throbber_message = "Preparing fake root";

    await $`mount -t tmpfs none /mnt`;
    await Deno.chmod("/mnt", 0o755);
    await Deno.mkdir("/mnt/boot");
    await Deno.chmod("/mnt/boot", 0o700);
    await Deno.mkdir("/mnt/etc");
}

interface Partition {
    label: string;
    type: string;
    size: string;
    cryptpass?: string;
    mount_path: string;
}

interface PartTypeFlags {
    skip_format_and_mount: boolean;
    format_command: string;
    volume_label_flag: string;
    additional_flags: Array<string>;
    mount_flags: Array<string>;
}

const partition_properties: Record<string, PartTypeFlags> = {
    "ef00": {
        skip_format_and_mount: false,
        format_command: "fat",
        volume_label_flag: "-n",
        additional_flags: ["32"],
        mount_flags: ["-o", "uid=0,gid=0,fmask=0077,dmask=0077"],
    },
    "8200": {
        skip_format_and_mount: true,
        format_command: "",
        volume_label_flag: "",
        additional_flags: [],
        mount_flags: [],
    },
    "8300": {
        skip_format_and_mount: false,
        format_command: "ext4",
        volume_label_flag: "-L",
        additional_flags: [],
        mount_flags: [],
    },
};

async function partition_disks(
    disk: string,
    partitions: Array<Partition>,
) {
    throbber_message = "Partitioning disks";
    for (const partition of partitions) {
        await $`cryptsetup luksClose ${partition.label}`.noThrow().quiet();
    }

    await $`sgdisk -Zog ${disk}`;
    for (const partition of partitions) {
        throbber_message = `Partitioning and mounting ${partition.label}`;

        await $`sgdisk -n 0:0:${partition.size} -t 0:${partition.type} -c 0:${partition.label} ${disk}`;
        const pp = partition_properties[partition.type];

        if (pp.skip_format_and_mount) continue;

        let partition_path = `/dev/disk/by-partlabel/${partition.label}`;
        await check_block_device(partition_path, 10);
        if (partition.cryptpass) {
            await $`cryptsetup luksFormat ${partition_path} -`
                .stdinText(partition.cryptpass);
            await $`cryptsetup luksOpen ${partition_path} ${partition.label} -`
                .stdinText(partition.cryptpass);

            partition_path = `/dev/mapper/${partition.label}`;
        }

        await $`mkfs.${pp.format_command} -F ${pp.additional_flags} ${pp.volume_label_flag} ${partition.label} ${partition_path}`;
        await sleep(2);

        Deno.mkdir("/mnt/" + partition.mount_path, { recursive: true });
        await $`mount ${pp.mount_flags} ${partition_path} /mnt/${partition.mount_path}`;
    }
}

async function post_disk_ready(userpass: string, hostname: string) {
    throbber_message = "Finishing setup";

    await Deno.mkdir("/mnt/nix/state/etc/nixos/secrets", { recursive: true });
    await Deno.chmod("/mnt/nix/state/etc/nixos/secrets", 0o0700);

    // Need this to sidestep impermanence
    await Deno.symlink("../nix/state/etc/nixos", "/mnt/etc/nixos");

    // Need this so we can have absolute paths for secrets
    await Deno.symlink(
        "../../mnt/nix/state/etc/nixos/secrets",
        "/etc/nixos/secrets",
    );

    await $`mkpasswd -s -m sha-512`
        .stdinText(userpass)
        .stdout($.path("/mnt/etc/nixos/secrets/ashwin_pass.txt"));

    await $`nixos-generate-config --root /mnt`;

    const default_configuration = `
{ ... }:
let
nixconfig = builtins.fetchGit {
  url = "https://github.com/ashwinvbs/nixconfig.git";
  ref = "main";
};
in
{
imports =
  [
    ./hardware-configuration.nix
    "\${nixconfig}"
    # (import "\${nixconfig}/utils/adduser.nix" { shortname = "user"; fullname = "User user"; persist = { directories = [ "." ]; }; })
  ];
  networking.hostName = "${hostname}";
}
`;

    await Deno.writeTextFile(
        "/mnt/etc/nixos/configuration.nix",
        default_configuration,
    );
}

function get_password(context: string): string {
    const pass = promptSecret("Enter password for " + context + ": ");
    if (!pass || pass.length < 5) {
        throw new Error("Invalid or insecure password provided for " + context);
    }
    return pass;
}

// Script start, preparation steps
if (Deno.uid() != 0) throw new Error("Script requires root privileges");

// Cleanup previous attempts if necessary
await $`umount -Rq /mnt`.noThrow();
try {
    await Deno.remove("/etc/nixos/secrets");
} catch (err) {
    if (!(err instanceof Deno.errors.NotFound)) throw err;
}

// Parse args
const flags = parseArgs(Deno.args, {
    string: ["disk", "machine", "swapsize"],
    boolean: ["encrypt"],
    default: { encrypt: true, disk: "", machine: "", swapsize: "0" },
    negatable: ["encrypt"],
});

const hostname: string = flags.machine?.toString() || "";
const disk: string = flags.disk.toString();
const encrypt: boolean = flags.encrypt;

if (!check_block_device(disk)) throw new Error("Invalid disk path.");
if (hostname.length == 0) throw new Error("Empty machine name provided");
const swapsize = parseInt(flags.swapsize?.toString() || "-1");
if (swapsize < 0) throw new Error("Invalid swap size provided");

// Gather passwords
const cryptpass: string | undefined = encrypt
    ? get_password("encrypted volume")
    : undefined;
if (encrypt && (!cryptpass || cryptpass.length < 5)) {
    throw new Error(
        "Invalid or insecure password provided for Cryptfs volume.",
    );
}

const userpass: string = get_password("user account");

// Call into main steps of setupfs
const throbber = start_throbber();

await prepare_fake_root();

await partition_disks(disk, [
    {
        label: "nixboot",
        type: "ef00",
        size: "+1G",
        mount_path: "/boot",
    },
    // Only includes this object if enableswap is true
    ...(swapsize > 0
        ? [{
            label: "swap",
            type: "8200",
            size: "+4G",
            mount_path: "/swap",
        }]
        : []),
    {
        label: "nixsystem",
        type: "8300",
        size: "0",
        cryptpass: cryptpass,
        mount_path: "/nix",
    },
]);

await post_disk_ready(userpass, hostname);

clearInterval(throbber);
