#!/usr/bin/env bash
function procspin(){
	[ $# -lt 1 ] && return 1
	local arg1 help oldIFS=$IFS hrx="^-[Hh]|--[Hh][Ee][Ll][Pp]$"
	help="\n\
 'procspin' - Ian Pride © 2020\n\
 Attach an animated progress spinner to a running process by\n\
 PID (Process ID). There is a default animation or you can\n\
 pass your own array or string of frames.\n\n\
 @USAGE: procspin <PID|SWITCH>... [SWITCH <STRING|ARRAY|INTEGER>]...\n\
 @PID: Process ID\n\
 	Integer 		The process id to attach to.\n\
 @SWITCH: Parameter switches.\n\
 	-h,--help 		This help message.\n\
 	-f,--frames		STRING or ARRAY of animation frames.\n\
 	-p,--prepend		STRING to prepend to spinner.\n\
 	-a,--append		STRING to append to spinner.\n\
 	-s,--spread		Time in INTEGER seconds to spread frames over.\n\n\
"
	case "$1" in
		(-[Hh]|--[Hh][Ee][Ll][Pp]) printf "$help"
		return;;
		*) arg1="$1"
		shift;;	
	esac
    if [ "$(ps a | awk '{print $1}' | grep $arg1)" > /dev/null 2>&1 ]; then
        local frame array pre app spread arg_i tmp
		if [ $# -gt 0 ]; then
            if [[ "$1" =~ $hrx ]] || \
                [[ "$2" =~ $hrx ]]; then
                printf "$help"
                return
            fi
			for arg_i in "$@"; do
				if [[ $1 =~ ^-[Pp]|--[Pp][Rr][Ee][Pp][Ee][Nn][Dd]$ ]]; then
					pre="$2"
					shift 2
				fi
				if [[ $1 =~ ^-[Aa]|--[Aa][Pp][Pp][Ee][Nn][Dd]$ ]]; then
					app="$2"
					shift 2
				fi
				if [[ $1 =~ ^-[Ff]|--[Fr][Rr][Aa][Mm][Ee][Ss]$ ]]; then
					IFS=',' read -r -a array <<< $2
					shift 2
					IFS=$oldIFS
				fi
				if [[ $1 =~ ^-[Ss]|--[Ss][Pp][Rr][Ee][Aa][Dd]$ ]]; then
					spread="$2"
					shift 2
				fi
			done
		fi
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
		while [ "$(ps a | awk '{print $1}' | grep $arg1)" > /dev/null 2>&1 ]; do
			for frame in "${array[@]}"; do
				printf "\r${pre}\e[92m${frame}\e[0m${app}"
				sleep "$(printf %.4f "$((10**3 * ${spread}/${#array[@]}))e-3")"
				printf "\r"
			done
		done
		printf "\n"
	else
		return 2
    fi
}
$(return >/dev/null 2>&1)
if [ "$?" -eq "0" ]; then
    complete -W "-h --help -a --append -p --prepend -s --spread" procspin
else
    procspin "$@"
fi