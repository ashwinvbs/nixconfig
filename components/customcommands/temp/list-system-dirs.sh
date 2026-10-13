#!/usr/bin/env bash
set -euo pipefail

echo "================================================================================"
echo "Inspecting Systemd Service Directories via Live System Introspection"
echo "================================================================================"
printf "%-32s %-14s %-40s %s\n" "SERVICE" "DIR TYPE" "PATH" "USER:GROUP"
echo "--------------------------------------------------------------------------------------------------------------"

# Map a directory property to (dir-type label, base prefix). For system services:
#   StateDirectory         -> /var/lib
#   RuntimeDirectory       -> /run
#   LogsDirectory          -> /var/log
#   ConfigurationDirectory -> /etc
#   CacheDirectory         -> /var/cache
DIR_PROPS=(
  "StateDirectory:state:/var/lib"
  "RuntimeDirectory:runtime:/run"
  "LogsDirectory:logs:/var/log"
  "ConfigurationDirectory:config:/etc"
  "CacheDirectory:cache:/var/cache"
)

# Enumerate EVERY installed service unit (list-unit-files) AND every currently
# loaded service (list-units). Using only list-units misses units that are not
# loaded (e.g. inactive services such as postgresql.service).
list_units() {
  {
    systemctl list-unit-files --type=service --no-legend 2>/dev/null | awk '{print $1}'
    systemctl list-units      --type=service --all --no-legend 2>/dev/null | awk '{print $1}'
  } | grep -vE '^$|@\.service$' | sort -u
}

list_units | while read -r unit; do
    [[ -z "$unit" ]] && continue

    # Fetch the properties we care about. NOTE: we deliberately avoid `eval`
    # here. systemctl returns multi-valued, space-separated lists such as
    #   StateDirectory=postgresql postgresql/17
    # and `eval` would try to *execute* the second word as a command.
    user="root"
    group="root"
    load_state=""
    declare -A dirvals=()

    while IFS='=' read -r key val; do
        case "$key" in
            User)  [[ -n "$val" ]] && user="$val" ;;
            Group) [[ -n "$val" ]] && group="$val" ;;
            LoadState) load_state="$val" ;;
            StateDirectory|RuntimeDirectory|LogsDirectory|ConfigurationDirectory|CacheDirectory)
                dirvals["$key"]="$val" ;;
        esac
    done < <(systemctl show "$unit" \
        --property=User --property=Group --property=LoadState \
        --property=StateDirectory --property=RuntimeDirectory \
        --property=LogsDirectory --property=ConfigurationDirectory \
        --property=CacheDirectory 2>/dev/null)

    # Skip units that don't actually exist (show returns defaults for these).
    [[ "$load_state" == "not-found" ]] && continue

    # Process each systemd directory type in a stable order.
    for entry in "${DIR_PROPS[@]}"; do
        IFS=':' read -r prop dtype prefix <<< "$entry"
        val="${dirvals[$prop]:-}"
        [[ -z "$val" ]] && continue

        # A single property may declare MULTIPLE directories (space-separated).
        for d in $val; do
            # Handle absolute vs relative paths returned by systemd.
            if [[ "$d" == /* ]]; then
                fullpath="$d"
            else
                fullpath="$prefix/$d"
            fi
            printf "%-32s %-14s %-40s %s\n" "$unit" "$dtype" "$fullpath" "$user:$group"
        done
    done
done
