#!/usr/bin/env bash

lines=10
order=up

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--lines)
            [[ $# -ge 2 && "$2" =~ ^[0-9]+$ ]] || { echo 'Expected a non-negative number after --lines' >&2; exit 1; }
            lines="$2"
            shift 2
            ;;
        -o|--order)
            [[ $# -ge 2 && ( "$2" == up || "$2" == down ) ]] || { echo 'Expected up or down after --order' >&2; exit 1; }
            order="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            [[ -z "${dir+x}" ]] || { echo 'Expected one directory' >&2; exit 1; }
            dir="$1"
            shift
            ;;
    esac
done

[[ -n "${dir:-}" && -d "$dir" ]] || { echo 'Usage: parse-logs.sh [-l NUMBER] [-o up|down] DIR' >&2; exit 1; }

export LC_ALL=C
pattern='^\[ (INFO|DEBUG|WARNING|ERROR) \][[:space:]][0-9]{2}:[0-9]{2}:[0-9]{4}[[:space:]](0|[1-9][0-9]*)[[:space:]][A-Za-z_]*$'

find "$dir" -type f -name '*.log' -exec grep -hE "$pattern" {} + |
    sort -k5,5nr |
    if [[ "$order" == up ]]; then
        head -n "$lines"
    else
        tail -n "$lines"
    fi
