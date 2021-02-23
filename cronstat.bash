#!/usr/bin/env bash

function cronstat {
    local path_mode=1 time_mode=1 bare_mode=0 arg
    if [[ $# -gt 0 ]]; then
        for arg in "$@"; do
            if [[ "$arg" =~ ^-([hH]|-[hH][eE][lL][pP])$ ]]; then
                cat<<EOF
 
 'cronstat' - 'stat' wrapper to find the oldest
 and newest file, directory, or both from an
 arrayed or line delimited list.
 
 @USAGE:
    cronstat <LIST> [OPTIONS...]
    <LIST> | cronstat [OPTIONS...]
 
 @LIST:
    Any arrayed list of files or directories
    or the output of the 'find' or 'ls'
    commands etc...
 
 @OPTIONS:
    -h,--help       This help screen.
    -b,--bare       Print the path only, no
                    extra information.
    -f,--file       Filter by files.
    -d,--directory  Filter by directories.
                    Defaults to any file or
                    directory.
    -o,--oldest     Get the oldest item.
                    Defaults to the newest.
 @EXAMPLES:
    cronstat \$(find -maxdepth 1)
    find -maxdepth 1 | cronstat
    IFS=\$(echo -en "\n\b") array=(\$(ls -A --color=auto))
    cronstat \${array[@]} --file
    printf '%s\n' "\${array[@]}" | cronstat -odb

 @EXITCODES:
    0               No errors.
    1               No array or list passed.
    2               No values in list.
 
EOF
                return
            fi
            if [[ "$arg" =~ ^-([bB]|-[bB][aA][rR][eE])$ ]]; then
                bare_mode=1
                shift
            fi
            if [[ "$arg" =~ ^-([fF]|-[fF][iI][lL][eE])$ ]]; then
                path_mode=2
                shift
            fi
            if [[ "$arg" =~ ^-([dD]|-[dD][iI][rR][eE][cC][tT][oO][rR][yY])$ ]]; then
                path_mode=3
                shift
            fi
            if [[ "$arg" =~ ^-([oO]|-[oO][lL][dD][eE][sS][tT])$ ]]; then
                time_mode=2
                shift
            fi
            if [[ "$arg" =~ ^-([oO][fF]|[fF][oO])$ ]]; then
                time_mode=2
                path_mode=2
                shift
            fi
            if [[ "$arg" =~ ^-([oO][dD]|[dD][oO])$ ]]; then
                time_mode=2
                path_mode=3
                shift
            fi
            if [[ "$arg" =~ ^-([oO][bB]|[bB][oO])$ ]]; then
                bare_mode=1
                time_mode=2
                shift
            fi

            if [[ "$arg" =~ ^-([fF][bB]|[bB][fF])$ ]]; then
                bare_mode=1
                path_mode=2
                shift
            fi
            if [[ "$arg" =~ ^-([dD][bB]|[bB][dD])$ ]]; then
                bare_mode=1
                path_mode=3
                shift
            fi

            if [[ "$arg" =~ ^-([oO][fF][bB]|[oO][bB][fF]|\
                            [bB][oO][fF]|[bB][fF][oO]|\
                            [fF][oO][bB]|[fF][bB][oO])$ ]]; then
                bare_mode=1
                time_mode=2
                path_mode=2
                shift
            fi
            if [[ "$arg" =~ ^-([oO][dD][bB]|[oO][bB][dD]|\
                            [bB][oO][dD]|[bB][dD][oO]|\
                            [dD][oO][bB]|[dD][bB][oO])$ ]]; then
                bare_mode=1
                time_mode=2
                path_mode=3
                shift
            fi
        done
    fi
    local input array date iter index=0 value time_string="Newest" path_string="File Or Directory"
    declare -A array
    if [[ ! -t 0 ]]; then
        while read -r input; do
            case "$path_mode" in
                1)  if  [[ -f "$input" ]] ||
                        [[ -d "$input" ]]; then
                        date=$(stat -c %Z "$input")
                        array[$date]="$input"
                    fi;;
                2)  if [[ -f "$input" ]]; then
                        path_string="File"
                        date=$(stat -c %Z "$input")
                        array[$date]="$input"
                    fi;;
                3)  if [[ -d "$input" ]]; then
                        path_string="Directory"
                        date=$(stat -c %Z "$input")
                        array[$date]="$input"
                    fi;;
            esac
        done
    else
        if [[ $# -gt 0 ]]; then
            for input in "$@"; do
                case "$path_mode" in
                    1)  if  [[ -f "$input" ]] ||
                            [[ -d "$input" ]]; then
                            date=$(stat -c %Z "$input")
                            array[$date]="$input"
                        fi;;
                    2)  if [[ -f "$input" ]]; then
                            path_string="File"
                            date=$(stat -c %Z "$input")
                            array[$date]="$input"
                        fi;;
                    3)  if [[ -d "$input" ]]; then
                            path_string="Directory"
                            date=$(stat -c %Z "$input")
                            array[$date]="$input"
                        fi;;
                esac
            done
        else return 1; fi
    fi
    if [[ ${#array[@]} -eq 0 ]]; then
         return 2
    fi
    for iter in "${!array[@]}"; do
        if [[ $index -eq 0 ]]; then
            index=$((index + 1))
            value=$iter
        fi
        case "$time_mode" in
            1)  if [[ $iter -gt $value ]]; then
                    value=$iter
                fi;;
            2)  if [[ $iter -lt $value ]]; then
                    time_string="Oldest"
                    value=$iter
                fi;;
        esac
    done
    value="${array[$value]}"
    if [[ $bare_mode -eq 0 ]]; then
        printf '\n%s %s:\n%s\n\nLast Changed:\n%s\n\n' \
            "$time_string" \
            "$path_string" \
            "$value" \
            "$(stat -c %z "$value")"
    else
        printf '%s\n' "$value"
    fi
}
if $(return >/dev/null 2>&1); then
    complete -W "-h --help -o --oldest -f --file -d --directory -b --bare -of -od -ob -fb -db -ofb -odb '\$(find -maxdepth 1)'" cronstat
else
    cronstat "$@"
fi
