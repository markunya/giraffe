#!/usr/bin/env bash

export LC_ALL=C
task=
dir=
top=10
year=
min_citations=0

while [[ $# -gt 0 ]]; do
    [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 1; }
    case "$1" in
        --task) task="$2" ;;
        --dir) dir="$2" ;;
        --top) top="$2" ;;
        --year) year="$2" ;;
        --min-citations) min_citations="$2" ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift 2
done

[[ -d "$dir" ]] || { echo 'Expected --dir DIRECTORY' >&2; exit 1; }
[[ "$task" == basic || "$task" == authors || "$task" == keywords ]] || { echo 'Expected --task basic|authors|keywords' >&2; exit 1; }
[[ "$top" =~ ^[0-9]+$ && "$min_citations" =~ ^[0-9]+$ && ( -z "$year" || "$year" =~ ^[0-9]+$ ) ]] || { echo 'Expected numeric filter values' >&2; exit 1; }

# Absolute paths also allow directory names starting with a dash.
dir=$(cd -- "$dir" && pwd)
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

find "$dir" -type f -name '*.csv' -print0 > "$tmp/files"
xargs -0 awk -F, '$1 != "pub_id" && NF == 6 { sub(/\r$/, ""); print }' < "$tmp/files" > "$tmp/data"

case "$task" in
    basic)
        printf 'Files: '
        tr -cd '\000' < "$tmp/files" | wc -c | awk '{ print $1 }'
        printf 'Publications: '
        cut -d, -f1 "$tmp/data" | sort | uniq | wc -l | awk '{ print $1 }'
        echo 'Journals:'
        cut -d, -f5 "$tmp/data" | sort | uniq
        ;;
    authors)
        cut -d, -f1,2,4 "$tmp/data" | sort -u > "$tmp/authors"
        echo 'Authors (publications):'
        cut -d, -f2 "$tmp/authors" | sort | uniq -c | sort -k1,1nr -k2 | head -n "$top" |
            awk '{ n=$1; sub(/^[[:space:]]*[0-9]+[[:space:]]+/, ""); print $0 " - " n }'
        echo 'Authors (citations):'
        sort -t, -k2,2 "$tmp/authors" |
            awk -F, 'NR > 1 && $2 != author { print total "\t" author; total=0 } { author=$2; total+=$3 } END { if (NR) print total "\t" author }' |
            sort -k1,1nr -k2 | head -n "$top" | awk -F '\t' '{ print $2 " - " $1 }'
        echo 'Years:'
        cut -d, -f1,3 "$tmp/data" | sort -u | cut -d, -f2 | sort | uniq -c |
            awk '{ print $2 " - " $1 }'
        ;;
    keywords)
        awk -F, -v year="$year" -v min="$min_citations" '(year == "" || $3 == year) && $4 >= min' "$tmp/data" > "$tmp/filtered"
        printf 'Records: '
        wc -l < "$tmp/filtered" | awk '{ print $1 }'
        echo 'Keywords:'
        cut -d, -f6 "$tmp/filtered" | sort | uniq -c | sort -k1,1nr -k2 | head -n 3 |
            awk '{ n=$1; sub(/^[[:space:]]*[0-9]+[[:space:]]+/, ""); print $0 " - " n }'
        echo 'Journals:'
        cut -d, -f5 "$tmp/filtered" | sort | uniq -c | sort -k1,1nr -k2 | head -n 3 |
            awk '{ n=$1; sub(/^[[:space:]]*[0-9]+[[:space:]]+/, ""); print $0 " - " n }'
        ;;
esac
