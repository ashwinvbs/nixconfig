#!/usr/bin/env bash
# Audit live permissions of impermanence-persisted directories against the
# intended permissions taken from:
#   (a) systemd-tmpfiles rules in /etc/tmpfiles.d and /run/tmpfiles.d
#   (b) systemd service directory properties
#       (StateDirectory / RuntimeDirectory / LogsDirectory /
#        ConfigurationDirectory / CacheDirectory + matching *DirectoryMode)
#
# Persisted directories are taken from the impermanence configuration as it
# manifests at runtime: the bind-mount units impermanence generates
# (unit fragment What=/nix/state/... , Where=<live path>).
#
# Every persisted directory is classified as one of:
#   MATCH                 reference permissions found, live permissions agree
#   MISMATCH              reference permissions found, live permissions differ
#   NO_REF (EXCEPTED)     no reference permissions; path matches an exception
#   NO_REF (NOT EXCEPTED) no reference permissions; path missing from exceptions
#
# Exit status: 1 if any MISMATCH or any NO_REF (NOT EXCEPTED), else 0.
set -euo pipefail

# ---------------------------------------------------------------------------
# Exceptions
#
# Persisted directories that are expected to have NO reference entry in the
# tmpfiles rules or the systemd service directory properties. Typical case:
# user-state directories declared in utils/adduser.nix with permissions given
# in the impermanence spec itself (e.g. { directory = ".ssh"; mode = "0700"; }).
#
# Entries are shell glob patterns matched against the full path. Exact paths
# work too, since a pattern without wildcards matches literally.
# ---------------------------------------------------------------------------
NO_REF_EXCEPTIONS=(
    # "/home/*/.ssh"
)

PERSIST_ROOT="/nix/state"

MODE_RE='^[0-7]{3,4}$'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
resolve_uid_name() {
    local id="$1" name
    if [[ "$id" =~ ^[0-9]+$ ]]; then
        name=$(getent passwd "$id" | cut -d: -f1) || name=""
        printf '%s' "${name:-$id}"
    else
        printf '%s' "$id"
    fi
}

resolve_gid_name() {
    local id="$1" name
    if [[ "$id" =~ ^[0-9]+$ ]]; then
        name=$(getent group "$id" | cut -d: -f1) || name=""
        printf '%s' "${name:-$id}"
    else
        printf '%s' "$id"
    fi
}

is_excepted() {
    local path="$1" pat
    for pat in "${NO_REF_EXCEPTIONS[@]}"; do
        [[ -n "$pat" ]] || continue
        if [[ "$path" == $pat ]]; then
            return 0
        fi
    done
    return 1
}

# ---------------------------------------------------------------------------
# Data set: tmpfiles_ref   path|mode|user|group|source
# Intended permissions from tmpfiles d/D/v rules.
# ---------------------------------------------------------------------------
collect_tmpfiles_ref() {
    # NOTE: find must not fail the script when a tmpfiles dir is absent
    {
        find /etc/tmpfiles.d /run/tmpfiles.d -name "*.conf" 2>/dev/null || true
    } | xargs -r cat 2>/dev/null |
        while read -r type path mode uid gid rest; do
            [[ -z "$type" || "$type" == \#* || "$type" == \;* ]] && continue
            [[ ! "$type" =~ ^[dDv]$ ]] && continue
            [[ "$path" != /* ]] && continue

            # tmpfiles allows "uid:gid" combined in the uid field
            if [[ "$uid" == *:* ]]; then
                gid="${uid#*:}"
                uid="${uid%%:*}"
            fi

            # Resolve tmpfiles defaults
            if [[ -z "$mode" || "$mode" == "-" ]]; then mode="0755"; fi
            if [[ -z "$uid" || "$uid" == "-" ]]; then uid="root"; fi
            if [[ -z "$gid" || "$gid" == "-" ]]; then gid="root"; fi

            # Skip non-plain modes (e.g. "0755:z", "~755") — not comparable
            if [[ ! "$mode" =~ $MODE_RE ]]; then continue; fi

            printf '%s|%s|%s|%s|tmpfiles\n' \
                "$path" \
                "$(printf '%04o' "$((8#$mode))")" \
                "$(resolve_uid_name "$uid")" \
                "$(resolve_gid_name "$gid")"
        done
}

# ---------------------------------------------------------------------------
# Data set: service_ref   path|mode|user|group|source
# Intended permissions from systemd service directory properties.
# ---------------------------------------------------------------------------
# prop:type:prefix:mode-prop
DIR_PROPS=(
    "StateDirectory:state:/var/lib:StateDirectoryMode"
    "RuntimeDirectory:runtime:/run:RuntimeDirectoryMode"
    "LogsDirectory:logs:/var/log:LogsDirectoryMode"
    "ConfigurationDirectory:config:/etc:ConfigurationDirectoryMode"
    "CacheDirectory:cache:/var/cache:CacheDirectoryMode"
)

list_service_units() {
    # Installed units AND loaded units — list-units alone misses inactive ones
    {
        systemctl list-unit-files --type=service --no-legend 2>/dev/null | awk '{print $1}'
        systemctl list-units --type=service --all --no-legend 2>/dev/null | awk '{print $1}'
    } | grep -vE '^$|@\.service$' | sort -u || true
}

collect_service_ref() {
    local unit user group load_state key val entry prop dtype prefix mprop
    local val_dirs d fullpath mode mode_norm
    local -A dirvals modevals

    list_service_units | while read -r unit; do
        [[ -z "$unit" ]] && continue

        # NOTE: deliberately no `eval` here — systemctl returns multi-valued
        # space-separated lists (e.g. StateDirectory=postgresql postgresql/17)
        # and eval would try to execute the second word as a command.
        user="root"
        group="root"
        load_state=""
        dirvals=()
        modevals=()

        while IFS='=' read -r key val; do
            case "$key" in
                User) [[ -n "$val" ]] && user="$val" ;;
                Group) [[ -n "$val" ]] && group="$val" ;;
                LoadState) load_state="$val" ;;
                StateDirectory | RuntimeDirectory | LogsDirectory | ConfigurationDirectory | CacheDirectory)
                    dirvals["$key"]="$val"
                    ;;
                StateDirectoryMode | RuntimeDirectoryMode | LogsDirectoryMode | ConfigurationDirectoryMode | CacheDirectoryMode)
                    modevals["$key"]="$val"
                    ;;
            esac
        done < <(systemctl show "$unit" \
            --property=User --property=Group --property=LoadState \
            --property=StateDirectory --property=StateDirectoryMode \
            --property=RuntimeDirectory --property=RuntimeDirectoryMode \
            --property=LogsDirectory --property=LogsDirectoryMode \
            --property=ConfigurationDirectory --property=ConfigurationDirectoryMode \
            --property=CacheDirectory --property=CacheDirectoryMode 2>/dev/null)

        # systemctl show prints defaults for units that do not exist
        [[ "$load_state" == "not-found" ]] && continue

        for entry in "${DIR_PROPS[@]}"; do
            IFS=':' read -r prop dtype prefix mprop <<< "$entry"
            val_dirs="${dirvals[$prop]:-}"
            [[ -z "$val_dirs" ]] && continue

            for d in $val_dirs; do
                if [[ "$d" == /* ]]; then
                    fullpath="$d"
                else
                    fullpath="$prefix/$d"
                fi

                mode="${modevals[$mprop]:-}"
                [[ -z "$mode" || "$mode" == "0" ]] && mode="0755"
                mode_norm=$(printf '%04o' "$((8#$mode))")

                printf '%s|%s|%s|%s|systemd:%s\n' \
                    "$fullpath" "$mode_norm" "$user" "$group" "$unit"
            done
        done
    done
}

# ---------------------------------------------------------------------------
# Data set: ref_perms   path|mode|user|group|source
# Union of tmpfiles_ref + service_ref, keyed by path.
# tmpfiles wins over service_ref (explicit rule > unit default); provenance of
# every contributing source is kept in the source field.
# ---------------------------------------------------------------------------
merge_ref() {
    # stdin: all ref records as path|mode|user|group|source, one per line
    awk -F'|' -v OFS='|' '
        {
            if ($1 == "") next
            path = $1; mode = $2; user = $3; group = $4; source = $5
            rank = (source == "tmpfiles") ? 1 : 2
            if (!(path in best_rank)) {
                best_rank[path] = rank
                best_mode[path] = mode
                best_user[path] = user
                best_group[path] = group
                best_source[path] = source
            } else {
                best_source[path] = best_source[path] ";" source
                if (rank < best_rank[path]) {
                    best_rank[path] = rank
                    best_mode[path] = mode
                    best_user[path] = user
                    best_group[path] = group
                }
            }
        }
        END {
            for (p in best_mode) print p, best_mode[p], best_user[p], best_group[p], best_source[p]
        }
    '
}

# ---------------------------------------------------------------------------
# Data set: ref_perms_live   path|mode|user|group|source
# ref_perms plus aliases with the $PERSIST_ROOT prefix stripped, so a rule for
# /nix/state/var/lib/tailscale is also the reference for live /var/lib/tailscale.
# ---------------------------------------------------------------------------
alias_state_paths() {
    # stdin: ref_perms; $1: root to strip
    awk -F'|' -v OFS='|' -v root="$1" '
        { rows[NR] = $0; primary[$1] = 1 }
        END {
            for (i = 1; i <= NR; i++) {
                print rows[i]
                split(rows[i], f, "|")
                if (index(f[1], root "/") == 1) {
                    live = substr(f[1], length(root) + 1)
                    if (live != "" && !(live in primary)) {
                        print live "|" f[2] "|" f[3] "|" f[4] "|" f[5] " (alias of " f[1] ")"
                    }
                }
            }
        }
    '
}

# ---------------------------------------------------------------------------
# Data set: persisted_dirs   path|what|unit
# Live impermanence-persisted directories: Where= of every mount unit whose
# fragment What= lives under $PERSIST_ROOT. File binds are out of scope for now.
# ---------------------------------------------------------------------------
collect_persisted_dirs() {
    local unit frag what where
    systemctl list-units --type=mount --all --no-legend 2>/dev/null | awk '{print $1}' |
        sort -u | while read -r unit; do
        [[ -z "$unit" ]] && continue
        frag=$(systemctl show -p FragmentPath --value "$unit" 2>/dev/null) || continue
        [[ -f "$frag" ]] || continue

        what=$(sed -n 's/^What=//p' "$frag" | head -n1)
        where=$(sed -n 's/^Where=//p' "$frag" | head -n1)
        [[ "$what" == "$PERSIST_ROOT" || "$what" == "$PERSIST_ROOT"/* ]] || continue
        [[ -n "$where" && "$where" == /* ]] || continue
        [[ -d "$where" ]] || continue # files are out of scope for now

        printf '%s|%s|%s\n' "$where" "$what" "$unit"
    done
}

# ---------------------------------------------------------------------------
# Data set: audit_rows   path|status|expected|actual|source
# One row per persisted directory, joined against ref_perms_live by path;
# actual permissions are read from the live filesystem.
# ---------------------------------------------------------------------------
audit_persisted_dirs() {
    # $1: ref_perms_live records (path|mode|user|group|source, newline-separated)    # stdin: persisted_dirs records (path|what|unit)
    local ref_table="$1"
    local path what unit status expected actual source
    local actual_mode actual_user actual_group exp_mode exp_user exp_group
    local norm_expected norm_actual exp_line

    while IFS='|' read -r path what unit; do
        [[ -z "$path" ]] && continue

        expected="-"
        actual="UNKNOWN"
        status="NO_REF"
        source="-"

        if [[ -d "$path" ]]; then
            actual_mode=$(stat -c '%a' "$path")
            actual_user=$(stat -c '%U' "$path")
            actual_group=$(stat -c '%G' "$path")
            actual="$(printf '%04o' "$((8#$actual_mode))") $actual_user:$actual_group"
        fi

        exp_line=$(printf '%s\n' "$ref_table" | awk -F'|' -v p="$path" '$1 == p { print; exit }')

        if [[ -n "$exp_line" ]]; then
            IFS='|' read -r _ exp_mode exp_user exp_group source <<< "$exp_line"
            expected="$exp_mode $exp_user:$exp_group"
            norm_expected=$((8#$exp_mode))
            if [[ "$actual" == "UNKNOWN" ]]; then
                status="MISMATCH"
            else
                norm_actual=$((8#$actual_mode))
                if ((norm_expected != norm_actual)) ||
                    [[ "$actual_user" != "$exp_user" || "$actual_group" != "$exp_group" ]]; then
                    status="MISMATCH"
                else
                    status="MATCH"
                fi
            fi
        fi

        printf '%s|%s|%s|%s|%s\n' "$path" "$status" "$expected" "$actual" "$source"
    done
}

print_section() {
    local title="$1" rows="$2"
    echo
    echo "--------------------------------------------------------------------------------"
    echo "$title"
    echo "--------------------------------------------------------------------------------"
    printf '%-32s %-18s %-24s %-24s %s\n' "PATH" "STATUS" "EXPECTED" "ACTUAL" "SOURCE"
    if [[ -z "$rows" ]]; then
        echo "(none)"
        return
    fi
    printf '%s\n' "$rows" | sort | while IFS='|' read -r path status expected actual source; do
        printf '%-32s %-18s %-24s %-24s %s\n' "$path" "$status" "$expected" "$actual" "$source"
    done
}
 
# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    local tmpfiles_ref service_ref ref_perms ref_perms_live persisted_dirs audit_rows
    local results_match results_mismatch results_no_ref_excepted results_no_ref_not_excepted
    local n_total n_match n_mismatch n_no_ref_excepted n_no_ref_not_excepted
    local path status expected actual source

    echo "========================================================================"
    echo "Auditing Permissions of Impermanence-Persisted Directories"
    echo "========================================================================"

    # Data set: reference permissions from both detectors
    tmpfiles_ref=$(collect_tmpfiles_ref)
    service_ref=$(collect_service_ref)

    # Data set: merged reference, then live-path aliases (/nix/state stripped)
    ref_perms=$(printf '%s\n%s\n' "$tmpfiles_ref" "$service_ref" | merge_ref)
    ref_perms_live=$(printf '%s\n' "$ref_perms" | alias_state_paths "$PERSIST_ROOT")

    # Data set: persisted directories (impermanence config, as mounted)
    persisted_dirs=$(collect_persisted_dirs)

    # Data set: one audit row per persisted directory (joined against ref_perms_live)
    audit_rows=$(printf '%s\n' "$persisted_dirs" | audit_persisted_dirs "$ref_perms_live")

    # Categorize
    results_match=""
    results_mismatch=""
    results_no_ref_excepted=""
    results_no_ref_not_excepted=""

    n_total=0
    n_match=0
    n_mismatch=0
    n_no_ref_excepted=0
    n_no_ref_not_excepted=0

    while IFS='|' read -r path status expected actual source; do
        [[ -z "$path" ]] && continue
        n_total=$((n_total + 1))
        case "$status" in
            MATCH)
                n_match=$((n_match + 1))
                results_match+="$path|$status|$expected|$actual|$source"$'\n'
                ;;
            MISMATCH)
                n_mismatch=$((n_mismatch + 1))
                results_mismatch+="$path|$status|$expected|$actual|$source"$'\n'
                ;;
            NO_REF)
                if is_excepted "$path"; then
                    n_no_ref_excepted=$((n_no_ref_excepted + 1))
                    results_no_ref_excepted+="$path|EXCEPTED|$expected|$actual|$source"$'\n'
                else
                    n_no_ref_not_excepted=$((n_no_ref_not_excepted + 1))
                    results_no_ref_not_excepted+="$path|NOT_EXCEPTED|$expected|$actual|$source"$'\n'
                fi
                ;;
        esac
    done <<< "$audit_rows"

    print_section "MATCHES" "${results_match%$'\n'}"
    print_section "MISMATCHES" "${results_mismatch%$'\n'}"
    print_section "NO_REF + EXCEPTED" "${results_no_ref_excepted%$'\n'}"
    print_section "NO_REF + NOT EXCEPTED" "${results_no_ref_not_excepted%$'\n'}"

    echo
    echo "================================================================================"
    echo "Summary: $n_total persisted dirs — $n_match match, $n_mismatch mismatch, $n_no_ref_excepted no-ref+excepted, $n_no_ref_not_excepted no-ref+not-excepted"
    echo "================================================================================"

    if ((n_mismatch > 0 || n_no_ref_not_excepted > 0)); then
        exit 1
    fi
    exit 0
}

main "$@"
