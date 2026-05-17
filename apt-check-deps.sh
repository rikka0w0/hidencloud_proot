#!/usr/bin/env bash
set -Eeuo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <package> [package ...]"
    echo
    echo "Example:"
    echo "  $0 squashfs-tools curl"
    exit 1
fi

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Error: command not found: $1" >&2
        exit 1
    }
}

need_cmd apt-cache
need_cmd dpkg-query
need_cmd awk
need_cmd sed
need_cmd sort

if command -v column >/dev/null 2>&1; then
    HAS_COLUMN=1
else
    HAS_COLUMN=0
fi

is_installed() {
    local pkg="$1"

    dpkg-query -W -f='${Status}\n' "$pkg" 2>/dev/null \
        | grep -q '^install ok installed$'
}

get_deps() {
    local pkg="$1"

    apt-cache depends \
        --recurse \
        --no-recommends \
        --no-suggests \
        --no-conflicts \
        --no-breaks \
        --no-replaces \
        --no-enhances \
        "$pkg" \
    | awk '
        /^[[:alnum:]][[:alnum:].+:-]*$/ {
            print $1
        }

        /^[[:space:]]*(PreDepends|Depends):/ {
            print $2
        }
    ' \
    | sed \
        -e 's/^<//' \
        -e 's/>$//' \
        -e '/^$/d' \
    | sort -u
}

for root_pkg in "$@"; do
    echo "Package: $root_pkg"
    echo

    if ! apt-cache show "$root_pkg" >/dev/null 2>&1; then
        echo "  Not found in current APT package index: $root_pkg"
        echo
        continue
    fi

    if [ "$HAS_COLUMN" -eq 1 ]; then
        {
            printf "STATUS\tPACKAGE\n"

            while IFS= read -r dep; do
                if is_installed "$dep"; then
                    printf "installed\t%s\n" "$dep"
                else
                    printf "missing\t%s\n" "$dep"
                fi
            done < <(get_deps "$root_pkg")
        } | column -t -s $'\t'
    else
        printf "%-10s %s\n" "STATUS" "PACKAGE"

        while IFS= read -r dep; do
            if is_installed "$dep"; then
                printf "%-10s %s\n" "installed" "$dep"
            else
                printf "%-10s %s\n" "missing" "$dep"
            fi
        done < <(get_deps "$root_pkg")
    fi

    echo
done
