#!/usr/bin/env bash
function split_chars {
    local array IFS=$(echo -en "\n\b")
    [ ! -t 0 ] && {
        local input
        while read -r input; do
            array+=( "$input" )
        done
    } || array=( "${@// /$' '}" )
    printf '%s' "${array[@]}" |
        grep --color=never -o .
}
$(return >/dev/null 2>&1)
[ "$?" -eq "0" ] ||
    split_chars "$@"
