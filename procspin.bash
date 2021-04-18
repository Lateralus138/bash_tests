#!/usr/bin/env bash
function procspin(){
	[[ $# -eq 0 ]] && return 1
	if [[ "$*" =~ -([hH]|-[hH][eE][Ll][pP]) ]]; then
		 printf "\n\
 'procspin'\n\
 Attach an animated progress spinner to a running process by\n\
 PID (Process ID). There is a default animation or you can\n\
 pass your own array or string of frames.\n\n\
 @USAGE:\n\t\
 procspin --pid <PID> [--SWITCH <STRING|ARRAY|INTEGER>]\n\n\
 @PID: Process ID\n\
 	Integer 		The process id to attach to.\n\n\
 @SWITCH: Parameter switches.\n\
 	-h, --help\tThis help message.\n\
 	-i, --pid\tInteger ID of process.\n\
 	-f, --frames\tSTRING or ARRAY of animation frames.\n\
 	-p, --prepend\tSTRING to prepend to spinner.\n\
 	-a, --append\tSTRING to append to spinner.\n\
 	-s, --spread\tTime in INTEGER seconds to spread frames over.\n\n"
		 return
	fi
	[[ $(($# % 2)) -eq 0 ]] || return 1 # Force all arguments to have a relative switch
	local arg1 oldIFS=$IFS frame array pre app spread arg_i tmp
	for arg_i in "$@"; do
		if [[ "$arg_i" =~ ^-([iI]|-[pP][iI][dD]$) ]]; then
			arg1="$2"
			shift 2
		fi
		if [[ "$arg_i" =~ ^-([pP]|-[pP][rR][eE][pP][eE][nN][dD]$) ]]; then
			pre="$2"
			shift 2
		fi
		if [[ "$arg_i" =~ ^-([aA]|-[aA][pP][pP][eE][nN][dD]$) ]]; then
			app="$2"
			shift 2
		fi
		if [[ "$arg_i" =~ ^-([fF]|-[fF][rR][aA][mM][eE][sS]$) ]]; then
			IFS=',' read -r -a array <<< "$2"
			shift 2
			IFS=$oldIFS
		fi
		if [[ "$arg_i" =~ ^-([sS]|-[sS][pP][rR][eE][aA][dD]$) ]]; then
			spread="$2"
			shift 2
		fi
	done
	if [[ -z  "$pre" ]]; then
		pre=""
	fi
	if [[ -z  "$app" ]]; then
		app=""
	fi
	if [[ -z  "$spread" ]]; then
		spread=1
	fi
	if [[ "${#array[@]}" -lt 1 ]]; then
		array=('' '' '' '' '' '' '' '' '' '' '' \
			'' '' '' '' '' '' '' '' '' '' '' '' '' '')
	fi
	if [ $(ps a | awk '{print $1}' | grep "$arg1") > /dev/null 2>&1 ]; then
		while [ $(ps a | awk '{print $1}' | grep "$arg1") > /dev/null 2>&1 ]; do
			for frame in "${array[@]}"; do
				printf "\r${pre}\e[92m${frame}\e[0m${app}"
				sleep "$(printf %.4f "$((10**3 * ${spread}/${#array[@]}))e-3")"
				printf "\r"
			done
		done
	else printf "\n"; fi
}
if $(return >/dev/null 2>&1); then
    complete -W "-h --help -a --append -p --prepend -s --spread" procspin
else
    procspin "$@"
fi
