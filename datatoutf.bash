#!/usr/bin/env bash
function datatoutf {
    if ! which iconv 2>&1>/dev/null; then return 1; fi
    if [[ $# -ge 2 ]]; then 
        if ! [[ -f "$1" ]]; then return 3; fi
    else return 2; fi
    if ! iconv -f ISO-8859-1 -t UTF-8//TRANSLIT "$1" -o "$2"; then
        return 4
    fi
}
if $(return >/dev/null 2>&1); then
    complete -W "$(find -maxdepth 1 -type f)" datatoutf
else datatoutf "$@"; fi
