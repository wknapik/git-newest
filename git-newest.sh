#!/usr/bin/env bash

set -eEo pipefail
shopt -s inherit_errexit >/dev/null 2>&1 || true

# Configuration.
readonly prog="$(basename "$0")"
declare -A opt=([ty]=files)
declare -a paths=(.)

# $@ := ""
help() {
    echo -e "USAGE: $prog [options] [path1 [path2 [...]]]

Print a NUL-separated list of versioned files or directories ordered from most
to least recently changed.

  -d | --directories\t\tlist directories [$([[ "${opt[ty]}" == directories ]] && echo true || echo false)]
  -f | --files\t\t\tlist files [$([[ "${opt[ty]}" == files ]] && echo true || echo false)]
  -h | --help\t\t\tprint this help and exit"
  exit 2
}

# $@ := program_arguments
parse_command_line() {
    local -a options; read -ra options <<<"$(getopt -u -o d,f,h -l directories,files,help -n "$prog" -- "$@" || true)"
    readonly options
    set -- "${options[@]}"
    while true; do
        case "$1" in
            -d|--directories) opt[ty]=directories; shift;;
            -f|--files) opt[ty]=files; shift;;
            -h|--help) help;;
            --) shift; break;;
            *) break;;
        esac
    done
    [[ -z "$*" ]] || paths=("$@")
    readonly opt paths
}

# $@ := [dir1 [dir2 [...]]]
# Based on https://stackoverflow.com/questions/19362345#answer-40535274
git_newest_files() {
    git ls-files -z -- "$@"|xargs -0 -P"$(nproc)" -n1 -I{} -- git log -z -1 --format="%at {}" "{}"|sort -zrn|cut -z -d' ' -f2-
}

# $@ := ""
# Based on https://unix.stackexchange.com/questions/444795#answer-504047
unsorted_uniq() {
    local i=0; while IFS= read -r -d '' line; do echo -ne "$((++i)) $line\0"; done|sort -zuk2|sort -znk1|cut -z -d' ' -f2-
}

# $@ := [dir1 [dir1 [...]]]
git_newest_directories() {
    git_newest_files "$@"|grep -zo '.*/'|unsorted_uniq
}

# $@ := program_arguments
main() {
    parse_command_line "$@"
    git_newest_"${opt[ty]}" "${paths[@]}"
}

main "$@"
