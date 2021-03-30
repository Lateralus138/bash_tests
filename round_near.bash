#!/usr/bin/env bash
function round_near {
  local arg="$1"
  if [[ "${arg:0:1}" =~ ^(-|\+)$ ]]; then
    local pre="${arg:0:1}"
    arg="${arg:1}"
  fi
  if [[ "$arg" =~ ^[0-9]+?\.?[0-9]+$ ]]; then
    local IFS='.' array
    array=( ${arg[@]} )
    if [[ -z "${array[0]}" ]]; then
      array[0]=0
    fi
    if [[ ${array[1]:0:1} -ge 5 ]]; then
      local  sum=0
      sum=$((${array[0]} + 1))
      printf '%s%d\n' "$pre" "$sum"
    else
      printf '%s%d\n' "$pre" "${array[0]}"
    fi
  else return 1; fi
}

if ! $(return >/dev/null 2>&1); then
  round_near "$@"
fi
