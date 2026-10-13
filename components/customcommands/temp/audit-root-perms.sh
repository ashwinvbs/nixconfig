#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "[!] Error: Must run with sudo." >&2
   exit 1
fi

echo "================================================================================"
echo "Auditing Live Root Filesystem Permissions against NixOS tmpfiles Rules"
echo "================================================================================"
printf "%-32s %-10s %-20s %s\n" "PATH" "STATUS" "EXPECTED (Mode User:Group)" "ACTUAL"
echo "--------------------------------------------------------------------------------"

find /etc/tmpfiles.d /run/tmpfiles.d -name "*.conf" 2>/dev/null | xargs cat 2>/dev/null | while read -r type path mode uid gid rest; do
    [[ -z "$type" || "$type" == \#* || "$type" == \;* ]] && continue
    [[ ! "$type" =~ ^[dDv]$ ]] && continue
    [[ "$path" != /* ]] && continue

    # Resolve defaults
    [[ "$mode" == "-" ]] && mode="0755"
    [[ "$uid" == "-" ]] && uid="root"
    [[ "$gid" == "-" ]] && gid="root"

    if [[ -d "$path" ]]; then
        # Fetch actual attributes
        actual_mode=$(stat -c "%a" "$path")
        actual_user=$(stat -c "%U" "$path")
        actual_group=$(stat -c "%G" "$path")

        # Normalize modes to integer base 8 to avoid padding mismatches (0700 vs 700)
        norm_expected_mode=$(( 8#$mode ))
        norm_actual_mode=$(( 8#$actual_mode ))

        # Resolve numeric user/group IDs if specified as numbers in tmpfiles
        expected_user="$uid"
        if [[ "$uid" =~ ^[0-9]+$ ]]; then
            expected_user=$(getent passwd "$uid" | cut -d: -f1 || echo "$uid")
        fi

        expected_group="$gid"
        if [[ "$gid" =~ ^[0-9]+$ ]]; then
            expected_group=$(getent group "$gid" | cut -d: -f1 || echo "$gid")
        fi

        expected_str="${mode} ${uid}:${gid}"
        actual_str="${actual_mode} ${actual_user}:${actual_group}"

        status="MATCH"
        if (( norm_expected_mode != norm_actual_mode )) || [[ "$actual_user" != "$expected_user" ]] || [[ "$actual_group" != "$expected_group" ]]; then
            status="MISMATCH"
        fi

        # Prints every evaluated path with its current match status
        printf "%-32s %-10s %-20s %s\n" "$path" "$status" "$expected_str" "$actual_str"
    fi
done
