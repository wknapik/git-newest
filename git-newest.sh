#!/usr/bin/env bash

set -eEo pipefail
shopt -s inherit_errexit >/dev/null 2>&1 || true

# Configuration.
readonly prog="$(basename "$0")"
declare -A opt=([ty]=files [min-depth]=0 [max-depth]="")
declare -a paths=(.)
trap help USR1

# $@ := ""
help() {
    echo -e "USAGE: $prog [options] [path1 [path2 [...]]]

Print a NUL-separated list of versioned files or directories ordered from most
to least recently changed.

  -d | --directories\t\tlist directories [$([[ "${opt[ty]}" == directories ]] && echo true || echo false)]
  -f | --files\t\t\tlist files [$([[ "${opt[ty]}" == files ]] && echo true || echo false)]
  -x | --min-depth\t\tminimum number of slashes [${opt[min-depth]}]
  -y | --max-depth\t\tmaximum number of slashes [${opt[max-depth]}]
  -h | --help\t\t\tprint this help and exit"
    exit 2
}

# $@ := program_arguments
parse_command_line() {
    local -a options; read -ra options <<<"$(getopt -uo d,f,h,x:,y: -l directories,files,help,min-depth:,max-depth: \
        -n "$prog" -- "$@" || kill -USR1 "$$")"
    set -- "${options[@]}"
    while true; do
        case "$1" in
            -d|--directories) opt[ty]=directories; shift;;
            -f|--files) opt[ty]=files; shift;;
            -x|--min-depth) opt[min-depth]="$2"; shift 2;;
            -y|--max-depth) opt[max-depth]="$2"; shift 2;;
            -h|--help) help;;
            --) shift; break;;
            *) break;;
        esac
    done
    [[ -z "$*" ]] || paths=("$@")
    readonly opt paths
}

# $@ := "files" | "directories" min_depth max_depth
fltr() {
    local -r ty="${1:?}" min_depth="${2:-0}" max_depth="$3"
    case "$ty,$min_depth,$max_depth" in
        files,0,) cat;;
        *,0,) grep -zo '.*/';;
        files,*) grep -zoE "^([^/]*/[^/]*){$min_depth,$max_depth}$";;
        *) grep -zoE "^([^/]*/){$min_depth,$max_depth}";;
    esac
}

# $@ := min_depth max_depth [dir1 [dir2 [...]]]
# Based on https://stackoverflow.com/questions/19362345#answer-40535274
git_newest_files() {
    local -r min_depth="${1:-0}" max_depth="$2"
    git ls-files -z -- "${@:3}"|fltr files "$min_depth" "$max_depth"|\
        xargs -0P "$(nproc)" -n1 -I{} -- git log -z -1 --format="%at {}" "{}"|sort -zrn|cut -zd' ' -f2-
}

# $@ := ""
# Based on https://unix.stackexchange.com/questions/444795#answer-504047
unsorted_uniq() {
    local i=0; while IFS= read -rd '' line; do echo -ne "$((++i)) $line\0"; done|sort -zuk2|sort -znk1|cut -zd' ' -f2-
}

# $@ := min_depth max_depth [dir1 [dir2 [...]]]
git_newest_directories() {
    local -r min_depth="${1:-0}" max_depth="$2"
    git_newest_files 0 "" "${@:3}"|fltr directories "$min_depth" "$max_depth"|unsorted_uniq
}

# $@ := program_arguments
main() {
    parse_command_line "$@"
    git_newest_"${opt[ty]}" "${opt[min-depth]}" "${opt[max-depth]}" "${paths[@]}"
}

main "$@"
