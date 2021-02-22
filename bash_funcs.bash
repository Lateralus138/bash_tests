#!/bin/bash
if [[ -f "${HOME}/bin/git-create.bash" ]]; then
	. "${HOME}/bin/git-create.bash"
fi
function bash_func_src {
    local file
    for file in $(find "${HOME}/.bash/profile/functions/" -maxdepth 1 -type f -name "*.bash"); do
        . "$file"
    done
}
bash_func_src
hash(){
	[ -r "$1" ] || return
	local hash
	for i in $(od $1); do
		hash+="$i"
	done
	echo "$hash"
}
hashfile(){
	[ -r "$1" ] || return
	local file dir
	file=$(basename "$1")
	[ "${file:0:1}" == "." ] && file=${file//./}
	dir=$(dirname "$1")
	[ "$dir" == "." ] && unset dir
	case "$file" in
		*.*) file=${file%%.*}_hashfile ;;
		*  ) file=${file}_hashfile ;;
	esac
	echo $(hash "$1") > "${dir}${file}"
}
hashcheck(){
	var="$2"
	if [ -z "${var+x}" ]; then
		echo Not "enough parameters passed."
		return
	fi
	if [[ ! -f "$1" ]] && [[ ! -f "$2" ]]; then
		echo "1 or more of $1 and $2 are not valid files."
		return
	fi
	a=$(hash  "$1")
	b=$(< "$2")
	if [ "$a" == "$b" ]; then
		echo "File: $1 hash is valid."
	else
		echo "File: $1 hash is not valid."
	fi
}
7zmax(){
	if [[ -d "$2" ]] || [[ -f "$2" ]]; then
		7z a -m0=lzma -mx=9 -mfb=64 -md=32m -ms=off "${1}.7z" "$2"
	fi
}
pause(){ [ $# -ne 0 ] && local msg="$*" || local msg="Press [Enter] to continue..."; read -r -p "$msg"; }
trash(){
	local trash=($@)
	for files in "${trash[@]}"; do
		mv "$files" "$HOME/.local/share/Trash/files/"
	done
}
desktop(){
    local file="$HOME/.local/share/applications/$1.desktop"
	if [[ -n "$1" ]] && [[ ! -f "$file" ]]; then
		echo -e "[Desktop Entry]\nName=\nGenericName=\nComment=\nExec=\nTerminal=false\nType=Application\nIcon=\nCategories=GNOME;GTK;Utility;" >> "$file"
	vim "$file"
	fi
}
psaux(){
	[ -n "$1" ] && tmp="$1" || return
	ps aux | grep "$tmp" | grep -v grep
}
truet(){
	[ -n "${1+x}" ]
}
findstr(){
	[ "$3" = "-a" ] && opt="sudo"
	[[ -d "$1" ]] && [[ -n "${2+x}" ]] && $opt grep -rnw "$1" -e "$2"
}
targs(){
	for i in ${@}; do [[ "$i" = "-a" ]] && opt="sudo"; done
	echo $opt
}
duck(){
	[ $# -ne 0 ] || return
	local s="https://duckduckgo.com/?q="
	for param in "$@"; do
		case "$param" in
			-type:*) local ia="&ia=${param//\-type\:/}" && continue
		esac
		s="${s}+$param"
	done
	xdg-open "${s}$ia"
}
google() {
    search=""
    echo "Googling: $*"
    for term in $@; do
        search="$search%20$term"
    done
    xdg-open "http://www.google.com/search?q=$search"
}
mntiso(){
	[ -f "$1" ] || return 1
	[ -d "/media/iso" ] || sudo mkdir -p /media/iso || return 1
	sudo mount -o loop "$1" /media/iso/
}
isnum(){
	[[ $1 =~ ^-?[0-9]+$ ]] && echo true
}
record(){
	[ "$#" -eq 0 ] && return 255
	if [ -n "$(isnum $1)" ]; then
		time="$1"
		file="$2"
	else
		time="$2"
		file="$1"
	fi
	[ -n "$time" ] && time="-d $time"
	arecord -f dat "$time" "$file"
}
WRITE_SECURE_SETTINGS(){
	[[ $# -ne 0 ]] && [[ -f "$HOME/bin/platform-tools/adb" ]] &&
	adb shell pm grant "$1" android.permission.WRITE_SECURE_SETTINGS
}
setifs(){ oldIFS=$IFS && IFS=$(echo -en "\n\b"); }
oldifs(){ [ "${oldIFS+x}" ] && IFS="$oldIFS"; }
bing(){
	local pre search term delim
	[ $# -ne 0 ] && pre="/search?q=" &&
	for term in $@;do
		[ -n "${search+x}" ] && delim=+ || delim=""
		search="$search$delim$term"
	done
	xdg-open "https://www.bing.com$pre$search"
	echo "Binging: $*"
}
mountiso(){
	local input mi="/media/iso"
	[ -d "$mi" ] || sudo mkdir -p $mi || return
	if [[ ! -f "$*" ]] || [[ ! -d "$*" ]]; then
		echo " [ Nothing mountable passed ] "
		return
	fi
	[ "$(mount | grep $mi)" ] &&
	read -p " [ $mi is mounted, would you like to unmount: Y/N? ] " input &&
	case "$input" in
		Y|y) 	sudo umount $mi;[ "$(mount | grep $mi)" ] &&
			echo " [ Could not unmount $mi ] " &&
			return;;
		*) 	echo " [ You did not unmount $mi ] " &&
			return;;
	esac
	sudo mount -o loop "$@" "$mi"
}
nulfile(){ [ $# -ne 0 ] && dd if=/dev/null of="$*"; }
filesize(){ [ -f "$*" ] && ls -al "$@" | awk '{print $5}'; }
rmnul(){ # Remove nul files in passed or current directory. Pass "-a" in any order for sudo
	local fPATH file root param oifs
	oifs=$IFS;IFS=$(echo -en "\n\b")
	for param in "$@"; do
		case "$param" in
			-a) root="sudo";;
			"$([[ -d "$param" ]] && echo "$param")") fPATH="$param";;
		esac
	done
	[ -n "${fPATH+x}" ] || fPATH="."
	for file in $($root find $fPATH -maxdepth 1 -type f); do
		[ $($root ls -al $file | awk '{print $5}') -eq 0 ] &&
		$root rm -f "$file"
	done
	IFS=$oifs
}
vimthemes(){ 	# list or preview vim themes; Usage: vimthemes [-p|--preview] [-u|--user]
		# if -u is not passed then search defaults to /usr/share/vim[0-9][0-9]/colors
		# otherwise $HOME/.vim/colors is checked for the calling user.
		# Preview will display the chosen theme with the themes file
		# instead of a list.
	local param theme userv modei pathv filev themev fldrv oifs
	for param in "$@"; do
		case "$param" in
			--[Pp][Rr][Ee][Vv][Ii][Ee][Ww]|-[Pp]	)	modei="vim";;
			--[Uu][Ss][Ee][Rr]|-[Uu]		)	userv=$(id -un);;
		esac
	done
	oifs=$IFS;IFS=$(echo -en "\n\b")
	[ -n "${modei+x}" ] || modei="echo"
	if [[ ! -d "/home/$(id -un)/.vim/colors" ]] && [[ "${userv+x}" ]]; then
		echo "Users Vim directory doesn't exist..."
		return
	fi
	if [ "${userv+x}" ]; then
		pathv="/home/$(id -un)/.vim/colors"
	else
		for fldrv in $(find /usr/share/vim -maxdepth 1 -type f); do
			if [[ $fldrv =~ vim.*[0-9] ]]; then
				pathv="/usr/share/vim/$fldrv/colors"
			fi
		done
		if [ ! "${pathv+x}" ]; then
			echo "No vim folder found..."
			return
		fi
	fi
	for theme in $(find $pathv -maxdepth 1 -type f -printf '%f\n'); do
		if [[ "$theme" =~ .*.vim ]]; then
			filev="$theme"
			themev="${theme//.vim/}"
		else continue;fi
		if [ "$modei" != "echo" ]; then
			vim -c "colorscheme $themev" ${pathv}/$filev
		else echo $themev; fi
	done
	IFS=$oifs
}
readfile(){
	[ $# -eq 0 ] || [ ! -f "$*"  ] && return
	local fline oifs=$IFS
	IFS=''
	while read -r fline; do echo "$fline"; done < "$@"
	IFS=$oifs
}
genqueries(){
	local line param qfile stime oifs=$IFS c=0
	IFS=$(echo -en "\n\b")
	for param in "$@"; do
		[ -f "$param" ] && qfile="$param"
		[ -n "$(isnum $param)"  ] && stime="$param"
	done
	[ "${qfile+x}" ] || return
	[ "${stime+x}" ] || stime=10
	for line in $(readfile $qfile); do
		c=$((c+1))
		[[ $((c % 10)) -eq 0 ]] && [[ "$(ps aux | grep firefox | grep -v grep)" ]] &&
		killall firefox && sleep 15
		echo -e "Binging query #${c}: $line"
		bing "$line"
		[ $c -eq 32 ] && break
		sleep $stime
	done
	IFS=$oifs
}
add(){
	local num sum
	for num in "$@"; do
		sum="$((sum + num))"
	done
	[ -n "${sum+x}" ] &&
	printf "$sum\n"
}
lsloop(){
	local opt opts
	[ $# -ne 0 ] &&
	for opt in "$@"; do
		[ -d "$opt" ] && dir="$opt"
	done
	[ -n "${opts+x}" ] &&
	echo -e "$opts\n$dir"
}
clearram(){ sudo bash -c 'sync && sudo echo 1 > /proc/sys/vm/drop_caches'; }
clearswap(){ sudo swapoff -a && sudo swapon -a; }
clearall(){ clearram;clearswap; }
editq(){ vim ~/Documents/slist.log; }
randfile(){
	[ $# -gt 0 ] &&
	local param th="-h:[0-9]+" tt="-t:[0-9]+" tv="-v:" tg="-g:" &&
	for param in "$@"; do
		[ -d "$param" ] && local dir="$param"
		[[ "$param" = "-s" ]] && local s && s="sudo"
		[[ $param =~ $th ]] && local h && h="head -n ${param//\-h\:/}"
		[[ $param =~ $tt ]] && local t && t="tail -n ${param//\-t\:/}"
		[[ $param =~ $tg ]] && local g && g="grep ${param//\-g\:/}"
		[[ $param =~ $tv ]] && local v && v="grep -v ${param//\-v\:/}"
	done
	[ ${dir+x} ] || local dir=/
	[ ${g+x} ] && [ ${v+x} ] && [ ${h+x} ] && [ ${t+x} ] && local mode=14
	[ ${g+x} ] && [ ${v+x} ] && [ ${h+x} ] && [ ! ${t+x} ] && local mode=13
	[ ${g+x} ] && [ ${v+x} ] && [ ${t+x} ] && [ ! ${h+x} ] && local mode=12
	[ ${g+x} ] && [ ${h+x} ] && [ ${t+x} ] && [ ! ${v+x} ] && local mode=11
	[ ${v+x} ] && [ ${h+x} ] && [ ${t+x} ] && [ ! ${g+x} ] && local mode=10
	[ ${g+x} ] && [ ${v+x} ] && [ ! ${h+x} ] && [ ! ${t+x} ] && local mode=9
	[ ${g+x} ] && [ ${h+x} ] && [ ! ${t+x} ] && [ ! ${v+x} ] && local mode=8
	[ ${g+x} ] && [ ${t+x} ] && [ ! ${h+x} ] && [ ! ${v+x} ] && local mode=7
	[ ${v+x} ] && [ ${h+x} ] && [ ! ${g+x} ] && [ ! ${t+x} ] && local mode=6
	[ ${v+x} ] && [ ${t+x} ] && [ ! ${g+x} ] && [ ! ${h+x} ] && local mode=5
	[ ${h+x} ] && [ ${t+x} ] && [ ! ${g+x} ] && [ ! ${v+x} ] && local mode=4
	[ ${g+x} ] && [ ! ${v+x} ] && [ ! ${h+x} ] && [ ! ${t+x} ] && local mode=3
	[ ${v+x} ] && [ ! ${g+x} ] && [ ! ${h+x} ] && [ ! ${t+x} ] && local mode=2
	[ ${h+x} ] && [ ! ${g+x} ] && [ ! ${v+x} ] && [ ! ${t+x} ] && local mode=1
	[ ${t+x} ] && [ ! ${g+x} ] && [ ! ${v+x} ] && [ ! ${h+x} ] && local mode=0
	printf "$mode\n"
	echo "Run Mode: $mode"
	case "$mode" in
		14) $s find "$dir" -type f | $g | $v | $h | $t ;;
		13) $s find "$dir" -type f | $g | $v | $h ;;
		12) $s find "$dir" -type f | $g | $v | $t ;;
		11) $s find "$dir" -type f | $g | $h | $t ;;
		10) $s find "$dir" -type f | $v | $h | $t ;;
		9) $s find "$dir" -type f | $g | $v ;;
		8) $s find "$dir" -type f | $g | $h ;;
		7) $s find "$dir" -type f | $g | $t ;;
		6) $s find "$dir" -type f | $v | $h ;;
		5) $s find "$dir" -type f | $v | $t ;;
		4) $s find "$dir" -type f | $h | $t ;;
		3) $s find "$dir" -type f | $g ;;
		2) $s find "$dir" -type f | $v ;;
		1) $s find "$dir" -type f | $h ;;
		0) $s find "$dir" -type f | $t ;;
		*) $s find "$dir" -type f | head -n 1 | tail -n 1 ;;
	esac
}
dailybing(){ genqueries $(. $HOME/.bash_funcs;randfile "$HOME" -g:".css\|rc" -v:".rcc" -h:$((1 + $RANDOM % 500)) -t:1 -s) 15; }
suppresserr(){ [ ! "$@" ] && echo -n "" || echo "$@"; }
even(){ ([ $# -ne 0 ] && [[ $(($1 % 2)) -eq 0 ]] && echo true || echo -n;) }
R(){ echo -n "${RANDOM:0:$(echo ${RANDOM:0:1} % ${RANDOM:0:1})}"; }
since(){ loginctl session-status | grep Since | head -n 1 | awk '{print $6 " " $7}'; }
psformat(){ ps aux | awk '{printf "\nUser: " $1}{printf "\nCommand: "}{for(a=11;a<=NF;a++)printf $a " "}{printf "\nPID: " $2}'; }
psff(){ local f="$HOME/psformat.log" && psformat > $f && xdg-open $f; }
testa(){ [ ${1+x} ] && printf "$1\n"; [ ${2+x} ] && printf "$2\n"; }
isnum(){
        [ $# -ne 0 ] &&
        if [[ $1 =~ ^-?[0-9]+$ ]]; then printf "$1"; fi      
}
chr(){
  local tmp
  [ $1 -lt 256 ] || return
  printf -v tmp '%03o' "$1"
  printf \\"$tmp"
}
function cpindv {
	local c i
	[[ -d "$1" ]] && [[ -d "$2" ]] || return
	c=0
	cd "$1"
	for i in *; do me[$c]="$i"; c=$(( c+1 )); done
	for i in "${me[@]}"; do ln -s  "${1}/${i}" "${2}/${i}"; done
}
function duckgo {
	[[ $# -gt 0 ]] || return
	all="$*"
	all="${all// /+}"
	xdg-open "https://duckduckgo.com/?q=${all}"
}
ansiweathert(){ ansiweather | awk '{print $6$7}'; }
function range(){
	[ $# -ge 2 ] &&
	[ $# -le 3 ] &&
	local tmp=$1 &&
	unset _range &&
	while [ $tmp -le $2 ]; do
		_range+=($tmp)
		tmp=$(( tmp + 1  ))
	done || return 1
}
function scumplay(){
	[ -x /usr/games/scummvm ] &&
	[ $# -gt 0 ] &&
	scummvm -f "$*" || return 1
}
function get_scum_ids() {
	local rc tmpa line
	rc="${HOME}/.scummvmrc"
	[ -f "${rc}" ] &&
	readarray tmpa < "${rc}"
	unset _scumids
	for line in "${tmpa[@]}"; do
		if [ "${line:0:1}" = "[" ]; then
			if [ "${line:1:7}" != "scummvm" ]; then
				_scumids+=("${line:1:$(( ${#line} - 3 ))}")
			fi
		fi
	done
}
function call() { [ $# -gt 0 ] && source "$*"; }
function lsp(){
	if [ $# -gt 0 ]; then
		params="$*"
		[[ "${params}" =~ .*'*'.* ]] ||
		[[ "${params:$(( ${#params} - 1 )):1}" == "/" ]] &&
		append="${params}*" || append="${params}/*"
		printf "%s\n" ${append}
	else
		printf "%s\n" *
	fi
}
function search() {
	if ! [ $# -gt 0 ]; then
		return 1
	fi
	local item dir qry
	for item in "$@"; do
		[ -d "${item}" ] &&
		dir="$item" ||
		qry="${qry} ${item}"
	done
	grep -rnw ${dir} -e ${qry}
}
function install_cursor(){
	[ $# -gt 0  ] ||
	return 1
	local int
	[[ $2 =~ ^-?[0-9]+$ ]] &&
	int=$2 || int=100
	[ -f "$1" ] &&
	sudo update-alternatives --install /usr/share/icons/default/index.theme x-cursor-theme "$1" $int ||
	return 1
}
function sethosts(){
	local file
	file=https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts
	if [[ "$(curl -s ${file})" != "$(cat /etc/hosts 2>/dev/null)" ]]; then
		sudo wget -q ${file} -O /etc/hosts &&
		echo "hosts file updated..." ||
		echo "Could not update hosts file..."
	fi
}
function txtfiletoimg(){
	if [[ $# -eq 2 ]]; then
		for param in "$@"; do
			[[ $param =~ ^(.*\.png|.*\.bmp|.*\.jpg|.*\.gif)$ ]] && local image=$param
			[[ "$(file -i $param | cut -d' ' -f2)" == "text/plain;" ]] && local text="$(cat $param)"
		done
	fi  
	[[ -n "$text" ]] &&
	[[ -n "$image" ]] &&
	convert \
	-fill black -font /home/flux/Downloads/Mincho.ttf \
	-density 288 -antialias \
	-pointsize 24 -quality 100 \
	-resize 25% \
	label:"$text" $image
}
function showcase_color(){
	for num in {0..7};do
		echo -e "\e[${num};97mStyle: ${num}\e[0m"
	done
	for num in {30..37} {90..97};do
		echo -e "\e[1;${num}mColor: ${num}\e[0m"
	done
	for num in {100..107};do
		echo -e "\e[${num};30mStyle: ${num}\e[0m"
	done
}
function listpkgs(){
	local array oifs=$IFS
    IFS= readarray array <<< $(apt list 2>/dev/null | grep "\[installed")
    IFS=$oifs
	for ((idx=0;idx<"${#array[@]}";idx++)); do
		array[$idx]="${array[$idx]//$'\n'}"
		array[$idx]="${array[$idx]//accountsservice}"
		array[$idx]="${array[$idx]%\/*}"
	done
	printf '%s\n' ${array[*]}
}
# Rainbow Bash Function
# Rainbow colorize input
# Usage: rainbow <any stdin>
# E.g.
#	- rainbow this is some example text
# 	- rainbow "$(cat some_file.txt)"
# 	- rainbow "$(echo -e "This is text\non two lines")"
function rainbow(){
	local params="$*" count=0 int clrs
	for int in {{91..96},{31..36}}; do
		clrs+=("${int}")
	done
	for ((index=0;index<${#params};index++)); do
		count=$((count + 1))
		echo -en "\e[${clrs[$((count - 1))]}m${params:${index}:1}\e[0m"
		[ $((count % 12)) -eq 0 ] && count=0
	done
	echo
}
function rgbtohex(){
	local int count R G B
	[ $# -gt 0 ] &&
	for int in "$@"; do
		count=$((count + 1))
        [[ "${int}" =~ ^[0-9]+$ ]] || return 2
		[[ "${int}" -eq "${int}" ]] && [[ "${int}" -le 255 ]] 2>/dev/null || return 3
		if [ $count -eq 1 ]; then
			[ $int -ge 16 ] && R=$(printf '%x' ${int}) || R="0$(printf '%x' ${int})"
		fi
		if [ $count -eq 2 ]; then
			[ $int -ge 16 ] && G=$(printf '%x' ${int}) || G="0$(printf '%x' ${int})"
		fi
		if [ $count -eq 3 ]; then
			[ $int -ge 16 ] && B=$(printf '%x' ${int}) || B="0$(printf '%x' ${int})"
		fi
	done || return 1
	echo "${R}${G}${B}"
}
function vimandx(){
	[ $# -gt 0 ] || return 1
	local item file
	for item in "$@"; do
		file+="${item}"
	done
	file="$(echo ${file} | xargs)"
	nvim "${file}" &&
	chmod +x "${file}"
}
function parseenv(){
	local	line lines nLines \
		lIdx prevLine thisLine \
		prevSChar prevEChar \
		thisSChar thisEChar \
		nextSChar nextEChar \
		eLines thisArr \
		nextLine
	declare -A env_array
	IFS="$(echo -en "\n\b")"
	for line in $(env); do
		lines+=(${line})
	done
	for lIdx in "${!lines[@]}"; do
		prevLine="${lines[$(($lIdx - 1))]}"
		thisLine="${lines[$lIdx]}"
		nextLine="${lines[$(($lIdx + 1))]}"
		prevSChar="${prevLine:0:1}"
		prevEChar="${prevLine:${#prevLine} - 1:1}"
		thisSChar="${thisLine:0:1}"
		thisEChar="${thisLine:${#thisLine} - 1:1}"
		nextSChar="${nextLine:0:1}"
		nextEChar="${nextLine:${#nextLine} - 1:1}"
		if	[[ "${prevEChar}" != \\ ]] &&
			[[ "${thisEChar}" != \\ ]] &&
			[[ "${thisLine}" =~ [=] ]]; then
			IFS='=' read -ra thisArr <<< "${thisLine}"
			env_array+=([${thisArr[0]}]=${thisArr[1]})
			IFS="$(echo -en "\n\b")"
			nLines+=(${thisLine})
		else
			eLines+=(${thisLine})
		fi
	done
#	for i in "${!finalArr[@]}"; do
#		echo "${i}"
#	done
#	for i in "${nLines[@]}"; do
#		echo "${i}"
#	done
#	for i in "${eLines[@]}"; do
#		echo "${i}"
#	done
	unset i IFS
	echo "${!finalArr[@]}"
}
function cursor_size(){
#	[[
	gsettings get org.gnome.desktop.interface cursor-size
}
function args_to_string(){
	echo -n "$*"
}
function isint(){
	[[ "$1" -eq "$1" ]] \
	> /dev/null 2>&1 &&
	echo true
}
function explorer(){
	wine "${HOME}/.wine/drive_c/windows/explorer.exe" "$*"
}
#
#	@USAGE:		files_by_size [DIRECTORY] [PARAMS]
#			Sort files in a directory at any depth.
#
#	@DIRECTORY:	Directory defaults to current
#			if not provided
#
#	@PARAMS:	All parameters are optional.
#	 Param	 Description
#	 -----	 -----------
#	 -h,--help	 This help message.
#	 -r,--reverse	 Sort order is reversed.
#	 -g,-G		 File sizes are Gigabytes.
#	 -m,-M		 File sizes are Megabytes.
#	 -k,-K		 File sizes are Kilobytes.
#	 -q		 Quiet, no header.
#	 -#		 Recursion level, defaults to infinite.
#	 -s,-S		 Force sudo, not needed if directory
#			 is owned by root.
#
function files_by_size(){
	local sortOpt="-n"
        local dir="$(realpath . 2>/dev/null)"
        local BS="M"
        local quiet depth sudov help
	if [ $# -gt 0 ]; then
		local array=("$@") prm
		for prm in "$@"; do
			case "${prm}" in
				-h|--help) help=true;;
				-r|--reverse) sortOpt+="r";;
				-[gG]|-[mM]|-[kK])	BS="${prm//-/}"
							BS=$(echo "${BS}" | tr '[a-z]' '[A-Z]');;
				-[qQ]) quiet=true;;
				-[0-9]*) depth="${prm//-/}";;
				-[sS]) sudov=true;;
				*) [ -d "$(realpath "${prm}" 2>/dev/null)" ] && dir="$(realpath "${prm}" 2>/dev/null)";;
			esac
		done
	fi
	if [[ -n "${help}" ]]; then
		echo -e "\n\t@USAGE:\t\tfiles_by_size [DIRECTORY] [PARAMS]"\
			"\n\t\t\tSort files in a directory at any depth."\
			"\n\n\t@DIRECTORY:\tDirectory defaults to current"\
			"\n\t\t\tif not provided"\
			"\n\n\t@PARAMS:\tAll parameters are optional."\
			"\n\t Param\t\t Description"\
			"\n\t -----\t\t -----------"\
			"\n\t -h,--help\t This help message."\
			"\n\t -r,--reverse\t Sort order is reversed."\
			"\n\t -g,-G\t\t File sizes are Gigabytes."\
			"\n\t -m,-M\t\t File sizes are Megabytes."\
			"\n\t -k,-K\t\t File sizes are Kilobytes."\
			"\n\t -q\t\t Quiet, no header."\
			"\n\t -#\t\t Recursion level, defaults to infinite."\
			"\n\t -s,-S\t\t Force sudo, not needed if directory"\
			"\n\t\t\t is owned by root.\n"
		return
	fi
	if [[ "$(stat -c '%U' "${dir}")" == "root" ]]; then
		sudov=true
	fi
	if [[ -z "${quiet}" ]]; then
		echo " Files sizes in ${BS}B's in ${dir}"
	fi
	if [[ -z "${depth}" ]]; then
		if [[ -n "${sudov}" ]]; then
			sudo find "${dir}" -type f -exec du --block-size=1"${BS}" {} \; | sort "${sortOpt}" 
		else
			find "${dir}" -type f -exec du --block-size=1"${BS}" {} \; | sort "${sortOpt}" 
		fi
	else
		if [[ -n "${sudov}" ]]; then
			sudo find "${dir}" -maxdepth "${depth}" -type f -exec du --block-size=1"${BS}" {} \; | sort "${sortOpt}" 
		else
			find "${dir}" -maxdepth "${depth}" -type f -exec du --block-size=1"${BS}" {} \; | sort "${sortOpt}" 
		fi
	fi
}
function tick_count(){
        which bc > /dev/null 2>&1 || return 1
	local tick=$(date +%s.%N)
	if [[ $# -gt 0 ]]; then
		case "${@^^}" in
			-R|--RESET)	unset start_tick stop_tick
                                        return 0;;
			-S|--START)     unset start_tick stop_tick
                                        start_tick="${tick}"
                                        return 0;;
			-T|--STOP)      stop_tick="${tick}"
                                        return 0;;
                        -D|--DIFF)      [[ -n "${start_tick}" &&
                                        -n "${stop_tick}" ]] &&
                                        bc <<< "${stop_tick} - \
                                                ${start_tick}" ||
                                        return 3
                                        return 0;;
                        -H|--HELP)      cat << EOF

 Usage: tick_count [OPTION]...
 Start or stop a timer or get the current tick count.
 Creates global variables \$start_tick and \$stop_tick.
 This is dependent on 'bc'.

 Options:
        -r, --reset     Reset global variables
        -s, --start     Set \$start_tick to current tick
        -t, --stop      Set \$stop_tick to current tick
        -d, --diff      Get difference between \$stop_tick
                        and \$start_tick     
        -h, --help      This help message & return

 Example: Benchmark counting files recursively
        -       tick_count -s   # start count
                sudo find . -type f | wc -l  # run command
                tick_count -t   # stop count
                tick_count -d   # echo difference

 Example: Get current tick count
        - tick_count

 Error Levels:
        1               'bc' was not found
        2               Incorrect parameters passed
        3               Both variables are not set

EOF
                                        return 0;;
		esac
		return 2
	fi
	echo "${tick}"
}
#function tick_count(){
#	local tick=$(date +%s.%N)
#	if [[ $# -gt 0 ]]; then
#		case "$@" in
#			[rR][eE][sS][eE][tT])	unset start_tick stop_tick;;
#			[sS][tT][aA][rR][tT])	start_tick="${tick}"
#						unset stop_tick;;
#			[sS][tT][oO][pP]) stop_tick="${tick}";;
#		esac
#		return 0
#	fi
#	echo "${tick}"
#}
#function tick_gap(){
#	if [[ $# -eq 2 ]]; then
#		local item
#		for item in "$@"; do
#			if ! [[ "${item}" =~ ^-?[0-9]*?\.?[0-9]*?$ ]]; then
#				return
#			fi
#		done
#		bc <<< "$2 - $1"
#	fi
#}
function ls_file_array(){
	local dir IFS=$(echo -en "\n\b")
	[[ -d "$*" ]] &&
	dir="$(realpath $*)" ||
	dir="$(realpath .)"
	file_array=($(find "$dir" -maxdepth -type f))
    printf '%s\n' ${file_array[@]}
}
#
function is_int_or_float(){ [[ "$1" =~ ^[-|+]?[0-9]*?\.?[0-9]*?$ ]] && return 0 || return 1; }
function is_math_symbol(){ [[ "$1" =~ ^[\+]?[\-]?[\/]?[\*]?[\(]?[\)]?$ ]] && return 0 || return 1; }
alias iiof='is_int_or_float'
alias ims='is_math_symbol'
#function math(){
#	which bc > /dev/null || return 1
#	local char
#	while read -n1 char; do
#		if ! (	iiof "${char}" ||
#			ims "${char}" ||
#			[[ "${char}" == " " ]]); then
#			return 1
#		fi
#	done < <(echo -n "$*")
#	echo "$*" | bc
#	return 0
#}
#complete -W "-h --help -s 0 1 2 3 4 5 6 7 8 9 + - * / ( )" bcmath
bc_opts=( -h --help -s 0 1 2 3 4 5 6 7 8 9 \+ \- \* \/ \( \) )
complete -W "$(printf '%s\n' "${bc_opts[@]}")" bcmath

# ⟬⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟭
# ⟬ Basic wrapper for the math cli 'bc'              ⟭
# ⟬ @USAGE: bcmath <PARAM> operation                 ⟭
# ⟬ 	bcmath -s4 "25/3" = 8.3333                   ⟭
# ⟬ 	bcmath "3*(2+3)" = 15                        ⟭
# ⟬     bcmath 3\*\(2+3\) = 15                       ⟭
# ⟬     bcmath "3 * (2 + 3)" = 15                    ⟭
# ⟬ @PARAM    	@DESCRIPTION                         ⟭
# ⟬ -h,--help	This help message                    ⟭
# ⟬ -s[n]		Decimal scale length         ⟭
# ⟬                                                  ⟭
# ⟬ @ERRORLEVEL: 1,2,3                               ⟭
# ⟬ 1		bc was not found	             ⟭
# ⟬ 2		Incorrect scale length 	             ⟭
# ⟬ 3		Incorrect mathematical operation     ⟭
# ⟬⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟡⟭

function bcmath(){
	which bc > /dev/null || return 1
	local item char scale params="$*" array=("$@")
	for item in "$@"; do
		case "${item}" in
			-h|--help)	cat << EOF

	Basic wrapper for the math cli 'bc'

 	@USAGE:	bcmath <PARAM> operation
	 	bcmath -s4 "25/3" = 8.3333
 		bcmath "3*(2+3)" = 15
		bcmath 3\*\(2+3\) = 15
		bcmath "3 * (2 + 3)" = 15

	@PARAM		@DESCRIPTION	
	-h,--help	This help message
	-s[n]		Decimal scale length

	@ERRORLEVEL: 	1,2,3
	1		bc was not found
	2		Incorrect scale length
	3		Incorrect mathematical operation

EOF
					return 0;;
				-s*)	if [[ "${item}" =~ ^-s[0-9]*$ ]]; then
						scale="${item//-s/}"
						shift
					else
						return 2
					fi;;
		esac
	done
	while read -n1 char; do
		[[ "${char}" =~ ^-?[0-9]*?\.?[0-9]*?$ ]] ||
		[[ "${char}" =~ ^[\+]?[\-]?[\/]?[\*]?[\(]?[\)]?$ ]] ||
		[[ "${char}" == " " ]] || return 3
	done < <(echo -n "$*")
	[[ -n "${scale}" ]] || scale=2
	echo "scale=${scale};$*" | bc
	return 0
}
#
function malert(){ echo -n "$?"; }
function ls_bash_opts(){ local item; while read -d: item; do echo "${item}"; done < <(echo -n "${BASHOPTS}"); }
function parse_str(){
	[[ $# -gt 0 ]] || return 1
	local delim item array
	for item in "$@"; do
		case "${item}" in
			-d*)	shift && delim="${item//-d/}";;
		esac
	done
	[[ -n "${delim}" ]] || delim=""
	IFS="${delim}" read -ra array <<< "$*"
	for item in "${array[@]}"; do
		echo "${item}"
	done
}

function printvar(){
	[[ -n "${!1}" ]] || return 1
	echo "${!1}";return 0
}

function avg {
    # TODO Add stdin pipe processing
    [[ $# -lt 2 ]] && return 1
	local value=0 iter array
	for iter in "$@"; do
		if [[ "${iter}" =~ ^-?[0-9]*?\.?[0-9]*?$ ]]; then
            value=$(echo "$value+$iter"|bc -l)
        else return 2; fi
	done
    sed -e 's/[0]*$//g;s/[\.]*$//g' <<< $(echo "$value/$#"|bc -l)
}
function is_array(){
	[[ "$(declare -p $1 2>/dev/null)" =~ "declare -a" ]] &&
	return 0 || return 1
}
# "
function testtimed(){
	local max param verb
	for param in "$@"; do
		case "${param}" in
			[0-9]*) max=$(expr ${param} - 1) && shift;;
			-v) verb=true && shift;;
		esac
	done
	test "${max}" -eq "${max}" > /dev/null 2>&1 ||
	max=$(expr 100 - 1)
	for ((i=0;i<=${max};i++)); do
		timed_array[$i]="$(timed)"
		if [[ -n "${verb}" ]]; then
			echo -e "timed_array[\e[1;91m$i\e[0m] = \e[1;92m${timed_array[$i]}\e[0m"
		fi
	done
}

#function echo(){ echo "$*" > /dev/full; }
function hextorgb(){
	local r="[0-9a-fA-F]"
	[[ "${1}" =~ ^${r}${r}${r}${r}${r}${r}$ ]] || return 1
	printf "%d %d %d\n" 0x${1:0:2} 0x${1:2:2} 0x${1:4:2}; return 0
}
function htr_string(){
        hextorgb $1|awk \
        '{sub(/[0-9]*/,$1",",$1);\
        sub(/[0-9]*/,$2",",$2);\
        print $1 $2 $3}'
}
function segment_intervals(){
	local idx regex="^[-|+]?[0-9]*?\.?[0-9]*?$"
	for idx in "$@"; do [[ "${idx}" =~ $regex ]] || return 1; done
	bcmath "${1}/(${2}-1)"
}
function git-acp(){
	local message="$*" stamp="$(date)"
    [[ $# -gt 0 ]] ||
        message="Generic Push: $stamp"
	if git add .; then
	    if git commit -m "${message}: $stamp"; then
        	git push -u origin master ||
                return 3
        else return 2; fi
    else return 1; fi
}
complete -W '-h --help -r --remove -a --add -q --quiet' todo
#function todo(){
#	local conf="${HOME}/.config/.todo"
#	local iterVal mode array
#	[[ -f "${conf}" ]] ||
#	cat /dev/null > "${conf}"
#	sed -i '/^\s*$/d' "${conf}"
#	case "$1" in
#		-h|--help)	mode=0 ;;
#		-r|--remove)	mode=1 ;;
#		-a|--add)	mode=2 ;;
#		*[0-9]*)	mode=3 ;;
#		-q|--quiet)	mode=4 ;;
#		*)		mode=5 ;;
#	esac
#	if [[ "${mode}" =~ ^[0-5]$ ]]; then
#		if [[ "${mode}" -eq 0 ]]; then
#			cat << EOF
#
#@Usage:	todo [INDEX]...
#     	todo [OPTIONS [INDEX|ITEM]...]...
#List, add, or remove todo items.
#
#@OPTIONS:
#	-h,--help	This help message.
#	-r,--remove	Remove an item by INDEX number.
#	-a,--add	Add an item by ITEM.
#	-q,--quiet	No error messages.
#@INDEX:
#	Integers	Index number of item.
#@ITEM:
#	String		Todo ITEM.
#@EXAMPLES:
#	todo -a "Something to do" # Add a todo item
#	todo -r 1 # Remove item at index #1
#
#EOF
#		elif [[ "${mode}" -eq 1 ]]; then
#			sed -i -e "${2}d" "${conf}"
#			return
#		elif [[ "${mode}" -eq 2 ]]; then
#			echo "$2" >> "${conf}"
#			return
#		elif [[ "${mode}" -eq 3 ]]; then
#			readarray -t array < "${conf}"
#			echo "${array[$((${1} - 1))]}"
#			return
#		else
#			readarray -t array < "${conf}"
#			if [[ ${#array[@]} -eq 0 ]]; then
#				[[ ${mode} -ne 4 ]] &&
#				echo "No items in the TODO list."
#				return
#			fi
#			for iterVal in "${!array[@]}"; do
#				echo "[$((${iterVal} + 1))]:${array[${iterVal}]}"
#			done
#			return
#		fi
#	fi
#}
function fzf-where() {
	if [[ $# -ge 1 ]]; then
		[[ -d "$*" ]] || return 1
	fi
	find "$(realpath $*)" | fzf
}
function fact() {
	[ $1 -lt 2 ] && echo 1 ||
	echo $(( $1 * $(fact $(( $1 - 1 ))) ))
}
function modx() {
	local iter sudov userv dir
	if [[ $# -gt 0 ]]; then
		for iter in "$@"; do
			case "${iter}" in
				-s|--sudo)	sudov=1 && shift;;
				-u|--user)	userv="u" && shift;;
			esac
		done
	fi
	[[ -d "$*" ]] && dir="$*" || dir="."
	if [[ $sudov -eq 1 ]]; then
		sudo chmod ${userv}+x $(find "$(realpath ${dir})" | fzf)
	else
		chmod ${userv}+x $(find "$(realpath ${dir})" | fzf)
	fi
}
function UniToInt() {
        if [[ $# -gt 0 ]]; then
                local ai bi ci di ei this br
                local range=(   "0" "1" "2" "3"
                                "4" "5" "6" "7"
                                "8" "9" "A" "B"
                                "C" "D" "E" "F")
                for ai in "${range[@]}"; do
                        if [[ "${ai}" == "2" ]]; then
                                break
                        fi
                        for bi in "${range[@]}"; do
                                for ci in "${range[@]}"; do
                                        for di in "${range[@]}"; do
                                                for ei in "${range[@]}"; do
                                                        if [[ "000${ai}${bi}${ci}${di}${ei}" == "00000000" ]]; then
                                                                continue
                                                        fi
                                                        this=$(printf '\U'"000${ai}${bi}${ci}${di}${ei}")
                                                        if [[ "${this}" == "$1"  ]]; then
                                                                echo "${ai}${bi}${ci}${di}${ei}"
                                                                return
                                                        fi
                                                done
                                        done
                                done
                        done
                done
        fi
}
function listuni() {
        local ai bi ci di ei
        local range=(   "0" "1" "2" "3"
                        "4" "5" "6" "7"
                        "8" "9" "A" "B"
                        "C" "D" "E" "F")
        for bi in "${range[@]}"; do
                for ci in "${range[@]}"; do
                        for di in "${range[@]}"; do
                                for ei in "${range[@]}"; do
                                        printf '\U'"000${ai}${bi}${ci}${di}${ei}"
                                done
                        done
                done
        done
}
function realfzf() {
        find "$(realpath $*)" -iname "*" | fzf
}
#function progspin(){
#        lcal frame pre char bs='\b\b\b'
#        if [ "$(ps a | awk '{print $1}' | grep $1)" > /dev/null 2>&1 ]; then
#                if [ -n "$2" ]; then
#                        for (( char=0; char<${#2}; char++ )); do
#                                bs+='\b'
#                        done
#                fi
#                while [ "$(ps a | awk '{print $1}' | grep $1)" > /dev/null 2>&1 ]; do
#                        for frame in ⭡ ⭧ ⭢ ⭨ ⭣ ⭩ ⭠ ⭦; do
#                                echo -en "${2}[\e[92m${frame}\e[0m]"
#                                sleep 0.125
#                                echo -en "${bs}"
#                        done
#                done
#                echo -en "${bs}"
#        fi
#}
#function progspin2(){
#        local frame pre char bs='\b\b\b'
#        if [ "$(ps a | awk '{print $1}' | grep $1)" > /dev/null 2>&1 ]; then
#                if [ -n "$2" ]; then
#                        for (( char=0; char<${#2}; char++ )); do
#                                bs+='\b'
#                        done
#                fi
#                while [ "$(ps a | awk '{print $1}' | grep $1)" > /dev/null 2>&1 ]; do
#                        # 
#                        #for frame in    ; do
#			local array=('' '' '' '' '' '' '' '' '' '' '' '' \
#				'' '' '' '' '' '' '' '' '' '' '' '' '')
#			#for frame in '\\' '|' '/' '-'; do
#			#for frame in '🌍' '🌎' '🌏'; do
#			#	echo -en " \r${2}[\e[92m${frame}\e[0m] $(date) "
#                        #        sleep 0.33
#                        #        echo -en " ${bs} "
#                        #done
#			for frame in "${array[@]}"; do
#				echo -en " \r${2}[\e[92m${frame}\e[0m] $(date) "
#                                sleep 0.04
#                                echo -en " ${bs} "
#                        done
#                done
#                echo -en "${bs}"
#        fi
#}
# function progspin(){
# 	[ $# -lt 1 ] && return 1
# 	local arg1=$1
#         if [ "$(ps a | awk '{print $1}' | grep $arg1)" > /dev/null 2>&1 ]; then
# 		shift
#         	local frame array pre
# 		if [ $# -gt 1 ]; then
# 			pre="$1"
# 			shift
# 		fi
# 		if [ $# -gt 1 ]; then
# 			array=("$@")
# 			shift
# 		else
# 			array=('' '' '' '' '' '' '' '' '' '' '' \
# 				'' '' '' '' '' '' '' '' '' '' '' '' '' '')
# 		fi
#                 while [ "$(ps a | awk '{print $1}' | grep $arg1)" > /dev/null 2>&1 ]; do
# 			for frame in "${array[@]}"; do
# 				printf "\r${pre}[\e[92m${frame}\e[0m] "
# 				sleep "$(echo "1 / ${#array[@]}" | bc -l)"
# 				printf "\r"
#                         done
#                 done
# 		printf "\n"
#         fi
# }
#function progspin(){
#        local frame pre char  # bs='\b\b\b'
#        if [ "$(ps a | awk '{print $1}' | grep $1)" > /dev/null 2>&1 ]; then
#                #if [ -n "$2" ]; then
#                #        for (( char=0; char<${#2}; char++ )); do
#                #                bs+='\b'
#                #        done
#                #fi
#		local array=('' '' '' '' '' '' '' '' '' '' '' \
#			'' '' '' '' '' '' '' '' '' '' '' '' '' '')
#                while [ "$(ps a | awk '{print $1}' | grep $1)" > /dev/null 2>&1 ]; do
#			for frame in "${array[@]}"; do
#				printf "\r${2}[\e[92m${frame}\e[0m] $(date) "
#				sleep "$(echo "1 / ${#array[@]}" | bc -l)"
#                                #printf " ${bs} "
#                        done
#                done
#                #echo -en "${bs}"
#        fi
#}
# function spinner() {
#     local pid=$1
#     local delay=0.75
#     local spinstr='|/-\'
#     while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
#         local temp=${spinstr#?}
#         printf " [%c]  " "$spinstr"
#         local spinstr=$temp${spinstr%$temp}
#         sleep $delay
#         printf "\b\b\b\b\b\b"
#     done
#     printf "    \b\b\b\b"
# }
# function progspin3(){
#         local frame pre char bs='\b\b\b'
#         if [ "$(ps a | awk '{print $1}' | grep $1)" > /dev/null 2>&1 ]; then
#                 if [ -n "$2" ]; then
#                         for (( char=0; char<${#2}; char++ )); do
#                                 bs+='\b'
#                         done
#                 fi
#                 while [ "$(ps a | awk '{print $1}' | grep $1)" > /dev/null 2>&1 ]; do
#                         for frame in '⊕' '⊗'; do
#                                 echo -en "${2}[\e[92m${frame}\e[0m]"
#                                 sleep 0.06125
#                                 echo -en "${bs}"
#                         done
#                 done
#                 echo -en "${bs}"
#         fi
# }
# function progspin4(){
#         local frame pre char bs='\b\b\b\b\b'
#         if [ "$(ps a | awk '{print $1}' | grep $1)" > /dev/null 2>&1 ]; then
#                 if [ -n "$2" ]; then
#                         for (( char=0; char<${#2}; char++ )); do
#                                 bs+='\b'
#                         done
#                 fi
#                 while [ "$(ps a | awk '{print $1}' | grep $1)" > /dev/null 2>&1 ]; do
#                         for frame in   ; do
#                                 echo -en " ${2}[\e[92m${frame}\e[0m] "
#                                 sleep 0.0625
#                                 echo -en "${bs}"
#                         done
#                 done
#                 echo -en "${bs}"
#         fi
# }
#⊕⊗
function pidbycommand() {
        if [ $# -gt 0 ]; then
                ps aux | \
                grep "$*" | \
                grep -v "grep" | \
                awk '{print $2}'
        fi
}
function rainbowtime(){
        local dt char bs slp="$1"
        [[ "${slp}" =~ ^[0-9]*?\.?[0-9]*?$ ]] &&
        slp="${slp}" || slp="0.5"
        [[ -n "${slp}" ]] || slp="0.5"
        while :; do
                bs='\b\b\b\b\b\b'
                dt="$(date)"
                for (( char=0; char<=${#dt}; char++ )); do
                        bs+='\b'
                done
                echo -en " [ $(rainbow ${dt}) ] "
                sleep "${slp}"
                echo -en "${bs}"
        done
}
if [[ -f "${HOME}/.bash/profile/procspin.bash" ]]; then
	. "${HOME}/.bash/profile/procspin.bash"
	function silent(){
		[ $# -gt 0 ] || return 1
		(eval $1 > /dev/null 2>&1) &
		procspin $! -p ' Running command: '"$1"' as PID: '"$!"' [' -a '] '
	}
fi
if [[ -f "${HOME}/.shell/scripts/YTSearchFilter/ytsf.bash" ]]; then
	. "${HOME}/.shell/scripts/YTSearchFilter/ytsf.bash"
fi
function marquee(){
        if [[ $# -gt 0 ]]; then
                local iter itercount rate
#                iter=$($*)
#                echo "${iter}"
                for iter in "$@"; do
                        case "${iter}" in
                                -[cC]:*|--[cC][oO][uU][nN][tT]:*) echo "${iter//aq}"
                                                                return ;;
                        esac
                done
        else return 1;fi
}
function repeatcmdonline(){ # TODO: Finish, create loop & error handling
        if [[ $# -gt 0 ]]; then
                local iter itercount delay comm
                for iter in "$@"; do
                        case "${iter}" in
                                -[cC]:*|--[cC][oO][uU][nN][tT]:*) \
                                        itercount="$(echo "${iter}" | \
                                        cut -d ':' -f2)"
                                        shift ;;
                                -[dD]:*|--[dD][eE][lL][aA][yY]:*) \
                                        delay="$(echo "${iter}" | \
                                        cut -d ':' -f2)"
                                        shift ;;
                        esac
                done
                echo "${itercount}"
        else return 1;fi
}
function closeallgrace(){
        local list id
        list=($(wmctrl -l | awk '{print $1}'))
        for id in "${list[@]}"; do
                echo -en "Closing ${id}"
                wmctrl -ic "${id}"
                sleep 0.5
                echo -en "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
                echo -en "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
                echo -en "Closed ${id}"
                sleep 0.5
        done
}
function countfilesf(){
        local dir recurse iter
        if [ $# -gt 0 ]; then
                for iter in "$@"; do
                        case "${iter}" in
                                -[rR])  recurse="R"
                                        shift;;
                        esac
                done
                if [ $# -gt 0 ]; then
                        if [ -d "$*" ]; then
                                dir="$*"
                        else
                                echo "Directory '$*' does not exist."
                                return 1
                        fi
                fi
        fi
        [ -n "${dir}" ] || dir="."
        ls -1A${recurse} "${dir}" | wc -l
}
function watchtime(){
        local sleep line len iter back
        if [[ $# -ge 1 ]]; then
                [[ $1 =~ ^[-|+]?[0-9]*?\.?[0-9]*?$ ]] &&
                sleep=$1 || return 1
        fi
        [[ -n "${sleep}" ]] || sleep="0.1"
        while :; do
                line=" 🕢 $(date "+%r") 🕢 "
                len=${#line}
                for iter in $(seq 1 $len); do back+="\b"; done
                echo -en "${line}"
                sleep $sleep
                echo -en "${back}"
        done
}
function all_spaces(){
        if [[ $# -gt 0 ]]; then
                local itr rplc
                for itr in "$@"; do
                        if [[ "${itr}" =~ ^-[rR]:.|^--[rR][eE][pP][lL][aA][cC][eE]:. ]]; then
                                rplc="$(echo "${itr}" | cut -d':' -f2)"
                                shift
                                break
                        fi
                done
                [[ $# -eq 0 ]] && return
                [[ -z "${rplc}" ]] && rplc="\t"
                echo "$*" | sed -e "s/[[:space:]]\+/${rplc}/g"
        fi
}
function watch_alt(){
        if [[ $# -gt 0 ]]; then
                local arg slp vrbs com lastComi chng
                for arg in "$@"; do
                        [[ "${arg}" =~ ^-[sS][0-9]*?\.?[0-9]*$ ]] &&
                        slp=${arg:2} && shift
                        [[ "${arg}" =~ ^-[vV]$ ]] &&
                        vrbs=1 && shift
                        [[ "${arg}" =~ ^-[cC]$ ]] &&
                        chng=1 && shift
                done
                lastCom=$(eval $*)
                while :;do
                        com=$(eval $*)
                        eval $*
                        [[ -n "${chng}" ]] &&
                        [[ "${com}" != "${lastCom}" ]] &&
                        return 0
                        [[ -n "${slp}" ]] && sleep "${slp}"
                        [[ -z "${vrbs}" ]] && clear
                        lastCom="${com}"
                done
                return 0
        fi && return 1
}
function debug(){
        local lastErr=$? lastPid=$!
        local lastProc=$(nameByPid ${lastPid})
        echo -e "$([[ "${lastErr}" -gt 0 ]] && \
                        echo -e " Last error: \033[31m${lastErr}\033[0m")\
                $([[ "${lastErr}" -gt 0 ]] && \
                        echo "\n" || \
                        echo -e "\r") Last PID: \033[33m${lastPid}\033[0m\
                $([[ -n "${lastProc}" ]] && echo "\n Last Process: ${lastProc}")\
                $([[ $# -gt 0 ]] && echo "\n Message: $*")"
        return
}
nameByPid(){
        if [[ ($# -gt 0 && $1 =~ ^[0-9]*$) ]];then
                local initArray=($(all_spaces -r:' ' "$(ps aux)" | cut -d' ' -f2,11))
                local iter pidArray procArray
                for ((  iter=1;\
                        iter<=$(echo "scale=0;\
                                ${#initArray[@]}+1" | bc -l);\
                        iter++)); do
                                        if [[ ($((${iter} % 2)) -eq 0 && \
                                                "${initArray[${iter}]}" =~ ^[0-9]*$) ]];then
                                        pidArray+=(${initArray[${iter}]})
                                        procArray+=(${initArray[${iter}+1]})
                        fi
                done
                for iter in ${!pidArray[@]}; do
                        if [[ "$1" == "${pidArray[${iter}]}" ]];then
                                echo "${procArray[${iter}]}"
                                return 0
                        fi
                done
                return 2
        fi
        return 1
}
pid_exists(){
        [[ $# -gt 0 ]] &&
        ([[ "$(echo $(all_spaces "$(ps aux)" | \
                cut -f2))" == *" $1 "* ]] && \
        return 0) || return 1
}
attach_to_pid(){
        while pid_exists $1;do sleep 0.9;done
}
file_to_array(){
	if [[ -f "$*" ]]; then
		[[ ${#_file_[@]} -gt 0 ]] &&
		unset _file_
		mapfile -t _file_ < <(cat "$*")
		[[ ${#_file_[@]} -gt 0 ]] &&
		return 0 || return 1
	fi
	return 1
}
function sms(){
        curl -X POST https://textbelt.com/text \
           --data-urlencode phone="$1" \
           --data-urlencode message="$2" \
           -d key=textbelt
}
function joinf(){
        if [[ $# -ge 3 ]]; then
                if [[ -f "$1" ]]; then
                        if [[ -f "$2" ]]; then
                                cat "$1" "$2" > "$3"
                                return 0
                        fi; return 3
                fi; return 2
        fi; return 1
}
# The following are variations of the above function that are slower
#function joinf1(){
#        if [[ $# -ge 3 ]]; then
#                if [[ -f "$1" ]]; then
#                        if [[ -f "$2" ]]; then
#                                cat "$1" "$2" > "$3"
#                        else
#                                return 3
#                        fi
#                else
#                        return 2
#                fi
#        else
#                return 1
#        fi
#}
#function joinf2(){ [[ $# -ge 3 ]] && ([[ -f "$1" ]] && ([[ -f "$2" ]] && cat "$1" "$2" > "$3" || return 3) || return 2) || return 1; }
#
#function joinf3(){
#        [[ $# -ge 3 ]] &&
#        ([[ -f "$1" ]] &&
#                ([[ -f "$2" ]] &&
#                        cat "$1" "$2" > "$3" ||
#                        return 3) ||
#                return 2) ||
#        return 1
#}
#function joinf4(){
#        if [[ $# -ge 3 ]]; then
#                if [[ -f "$1" ]]; then
#                        if [[ -f "$2" ]]; then
#                                cat "$1" "$2" > "$3"
#                                return 0
#                        fi
#                        return 3
#                fi
#                return 2
#        fi
#        return 1
#}
function badge(){
        if [[ $# -ge 3 ]]; then
                local argv argn
                for argv in "$@"; do
                        argn+=("${argv// /%20}")
                done
                echo "https://img.shields.io/badge/${argn[0]}-${argn[1]}-${argn[2]}"
                return 0
        fi
        return 1
}
function git-badge(){
        if [[ $# -ge 4 ]]; then
                local arg alt
                for arg in "$@"; do
                        alt="${arg}"
                        shift
                        break
                done
                echo '!['"${alt}"']('"$(badge "$@")"')'
                return 0
        fi
        return 1
}
function getmousecoords(){
        xdotool getmouselocation|awk \
                '{sub(/^x:/,"",$1);\
                sub(/^y:/,"",$2);\
                print $1 " " $2}'
}
function metro-colors(){
        local array idx
        declare -A array
        array=( ["light green"]=99B433 ["green"]=00A300\
                ["dark green"]=1E7145 ["magenta"]=FF0097\
                ["light purple"]=9F00A7 ["purple"]=7E3878\
                ["dark purple"]=603CBA ["darken"]=1D1D1D\
                ["teal"]=00ABA9 ["light blue"]=EFF4FF\
                ["blue"]=2D89EF ["dark blue"]=2B5797\
                ["yellow"]=FFC40D ["orange"]=E3A21A\
                ["dark orange"]=DA532C ["red"]=EE1111\
                ["light red"]=B91D47 ["white"]=FFFFFF)
        if [[ $# -gt 0 ]]; then
                if [[ "${array[$@]}" != "" ]]; then
                        echo "${array[$@]}"
                        return 0
                fi
                return 1
        fi
        for idx in "${!array[@]}"; do
                echo "${idx}:${array[${idx}]}"
        done
}
function workspace(){
        local   pre="{\n\t\"folders\": [" path\
                body="\n\t\t{\n\t\t\t\"path\": \"<REPLACE>\"\n\t\t},"\
                suf="\n\t],\n\t\"settings\": {}\n}" iter\
                file="<REPLACE>.code-workspace"
        if [[ $# -gt 0 ]]; then
                if [[ "${1^^}" =~ ^-H|-HELP$ ]]; then
                        cat<<EOF

 Usage: workspace <FILE TITLE | PARAM>... [DIRECTORY1 DIRECTORY2 DIRECTORIES*]...
 Create a '.code-workspace' file with given 'FILE TITLE' and optional
 directories for VSCode. This only creates a base file to start with
 with no 'settings' options, but you can add as many directies as you
 like as long as they exist. If a passed directory doesn't exist then
 ERRORLEVEL '3' will be thrown. <FILE TILE> is not optional and will
 throw ERRORLEVEL 1.

 FILE TILE:             Any possible Linux file name
                        without the extension
                        '.code-workspace'. If the path
                        is not provided with the file
                        name then it will be created
                        in the current path.
                        This is not optional and will
                        throw an ERRORLEVEL.
                       
 PARAM:
        -h, --help      This HELP message and return.

 DIRECTORIES:           Pass any existing directories
                        full path delimited by spaces.
                        This is optional.
                        Nonexistent directories will
                        throw an ERRORLEVEL.

 EXAMPLES:
        workspace "Fake_Project" "/path/with spaces/" /path/without/spaces
                        Creates 'Fake_Project.code-workospace' in the
                        current directory with 2 directories.

        workspace "\$(basename \$(realpath .))" \$(find \$(realpath .) -maxdepth 1 -type d)
                        Creates 'NameOfCurrentDirectory.code-workspace' with the current
                        directory and all of it's sub directories added.

        workspace /home/fakename/.project/FileName
                        Creates 'FileName.code-workspace' in /home/fakename/.project/
                        with '.' as it's only directory.
 ERRORLEVEL:
        1               Nothing passed.
        2               Invalid FILE TITLE passed.
        3               A passed directory does not exist.

EOF
                        return
                fi
                if [[ "$1" =~ [^/]+ ]]; then
                        file="${file//<REPLACE>/$1}"
                        shift
                else
                        return 2
                fi
        else
                return 1
        fi
        if [[ $# -gt 0 ]]; then
                for iter in "$@"; do
                        [[ ! -d "${iter}" ]] && return 3
                        path+="${body//<REPLACE>/${iter}}"
                done
                echo -e "$pre$path$suf">"${file}"
                return
        fi
        echo -e "$pre${body//<REPLACE>/.}$suf">"${file}"
}
function ControlSend(){
        if [[ $# -gt 0 ]]; then
                xdotool keydown Control
                xdotool key "$*"
                xdotool keyup Control
        fi
}
function ModKeys(){
        if [[ $# -gt 1 ]]; then
                local mods arg
                for arg in "$@"; do
                        case "${arg^^}" in
                                CONTROL|CTRL)   mods+=($arg)
                                                shift;;
                                SHIFT)          mods+=($arg)
                                                shift;;
                                ALT)            mods+=($arg)
                                                shift;;
                        esac
                done
                if [[ "${#mods}" -gt 0 ]]; then
                        if [[ $# -gt 0 ]]; then
                                for arg in "${mods[@]}"; do
                                        xdotool keydown "${arg}"
                                        sleep 0.25
                                done
                                xdotool key "$*"
                                sleep 0.25
                                for arg in "${mods[@]}"; do
                                        xdotool keyup "${arg}"
                                        sleep 0.25
                                done
                                [[ $? -gt 0 ]] && return 4
                                return
                        fi
                        return 3
                fi
                return 2
        fi
        return 1
}
function mc_chunk_get(){
        if [[ $# -ge 2 ]]; then
                local arg x y
                for arg in "$@"; do
                        [[ "${arg}" =~ ^[-|+]?[0-9]+$ ]]||return 2
                done
                x=$1 y=$2
                while [[ $((x % 16)) -ne 0 ]]; do
                        x=$((x-1))
                done
                while [[ $((y % 16)) -ne 0 ]]; do
                        y=$((y-1))
                done
                printf "%s\n" "$x,$y to $((x+15)),$((y+15))"
                return
        fi
        return 1
}
function newline(){
        local dir
        if [[ "${*^^}" =~ UP ]]; then
                xdotool key 0xe0 0x48 0xe0 0xc8
        fi
        xdotool key 0xe0 0x4f 0xe0 0xcf
        xdotool key 0x1c 0x9c
}
function toclip(){
        if [[ $# -gt 0 ]]; then
                clipit -c <<<"$*">/dev/null
                return
        fi
        return 1
}
function format_pyspec(){
        for i in "${_file_[@]}"; do
                echo "('${i}',None,None),"
        done
}
function dec_to_hex(){ is_int $1 || return;printf "%x" "$1"; }
function hex_to_dec(){ printf "%d" "$1"; }
function is_int() { return $(test "$@" -eq "$@" > /dev/null 2>&1); }
function printu(){
	full=00000000
	printf "\U${full::-${#1}}${1}"
}
function range(){
	is_int $1 || return
	is_int $2 || return
	range=($(for i in $(seq $1 $2); do printf "$i "; done))
	echo "${range[@]}"
}
function list_uni(){
	if [[ $# -gt 0 ]]; then
		hex=$(dec_to_hex $1)
		printu $hex
		printf " "
		return
	fi
	for int in {0..131071}; do
		hex=$(dec_to_hex $int)
		printf "0x${hex}: "
		printu $hex
		printf " "
		[[ $(($(($int +1)) % 16)) -eq 0 ]] &&
		printf "\n"
	done
}
function list_1e000(){
	r1=($(seq 125184 125259))
	r2=($(seq 125264 125273))
	r3=($(seq 125278 125279))
	r4=($(seq 126464 126467))
	r5=($(seq 126469 126495))
	r6=($(seq 126497 126498))
	r7=(126500)
	r8=(126503)
	r9=($(seq 126505 126514))
	r10=($(seq 126516 126519))
	r11=(126521)
	r12=(126523)
	r13=($(seq 126561 126562))
	r14=(126564)
	r15=($(seq 126567 126570))
	r16=($(seq 126572 126578))
	r17=($(seq 126580 126583))
	r18=(126590)
	for int in {${r1[@]},${r2[@]},${r3[@]},${r4[@]},${r5[@]},${r6[@]},${r7[@]},${r8[@]},${r9[@]},${r10[@]},${r11[@]},${r12[@]},${r13[@]},${r14[@]},${r15[@]},${r16[@]},${r17[@]},${r18[@]}}; do
		hex=$(dec_to_hex $int)
		printu $hex
		printf " "
	done
	printf "\n"
}
function list_1f000(){
	r1=($(seq 126976 127019))
	r2=($(seq 127024 127123))
	r3=($(seq 127136 127150))
	r4=($(seq 127153 127167))
	r5=($(seq 127169 127183))
	r6=($(seq 127185 127221))
	r7=($(seq 127232 127244))
	r8=($(seq 127248 127340))
	r9=($(seq 127344 127404))
	r10=($(seq 127462 127490))
	r11=($(seq 127504 127547))
	r12=($(seq 127552 127560))
	r13=($(seq 127568 127569))
	r14=($(seq 127744 128722))
	r15=($(seq 128736 128748))
	r16=($(seq 128752 128762))
	r17=($(seq 128768 128883))
	r18=($(seq 128896 128901))
	r19=(128903)
	r20=(128905)
	r21=($(seq 128908 128909))
	r22=($(seq 128913 128920))
	r23=($(seq 128922 128926))
	r24=($(seq 128928 128960))
	r25=($(seq 128962 128964))
	r26=($(seq 128966 128970))
	r27=($(seq 128972 128974))
	r28=(128976)
	r29=(128978)
	r30=(128980)
	r31=($(seq 128992 128827))
	r32=($(seq 129024 129035))
	r33=($(seq 129040 129095))
	r34=($(seq 129104 129113))
	r35=($(seq 129120 129159))
	r36=($(seq 129168 129197))
	r37=($(seq 129293 129535))
	r38=($(seq 129648 129651))
	r39=($(seq 129656 129658))
	r40=($(seq 129664 129666))
	r41=($(seq 129680 129685))
	#count=0
	for int in {${r1[@]},${r2[@]},${r3[@]},${r4[@]},${r5[@]},${r6[@]},${r7[@]},${r8[@]},${r9[@]},${r10[@]},${r11[@]},${r12[@]},${r13[@]},${r14[@]},${r15[@]},${r16[@]},${r17[@]},${r18[@]},${r19[@]},${r20[@]},${r21[@]},${r22[@]},${r23[@]},${r24[@]},${r25[@]},${r26[@]},${r27[@]},${r28[@]},${r29[@]},${r30[@]},${r31[@]},${r32[@]},${r33[@]},${r34[@]},${r35[@]},${r36[@]},${r37[@]},${r38[@]},${r39[@]},${r40[@]},${r41[@]}}; do
		#count=$(($count + 1))
		hex=$(dec_to_hex $int)
		printu $hex
		#printf " "
	done
	#printf "\n$count"
	printf "\n"
}
function fcl(){ cat "$1" | wc -c; }
function fortcproj(){
	[[ $# -eq 0 ]] && return
    mkdir ${HOME}/fortran/projects/crossplatform/$1 &&
    workspace ${HOME}/fortran/projects/crossplatform/${1}/${1} &&
    nulfile ${HOME}/fortran/projects/crossplatform/${1}/${1}.f95 &&
    cd ${HOME}/fortran/projects/crossplatform/$1
}
#function lastmodified(){
#	[[ $# -eq 0 ]] && return 1
#	echo -e " Attempting to update \033[91mLocate Database\033[0m..."
#	sudo updatedb || return 2
#	local str_mod=($(locate $*)) file
#	echo -e " Searching for \033[91m$*\033[0m..."
#	for file in "${str_mod[@]}"; do
#		stat "${file}" |
#		grep "File\|Modify" ||
#		return 3
#	done
#}
function towife(){
	[[ $# -eq 0 ]] && return
	mutt 2175208499@sms.myboostmobile.com <<< "$*"
}
# function procspin(){
# 	[ $# -lt 1 ] && return 1
# 	local arg1 help oldIFS=$IFS hrx="^-[Hh]|--[Hh][Ee][Ll][Pp]$"
# 	help="\n\
#  'progspin' - Ian Pride © 2020\n\
#  Attach an animated progress spinner to a running process by\n\
#  PID (Process ID). There is a default animation or you can\n\
#  pass your own array or string of frames.\n\n\
#  @USAGE: progspin <PID|SWITCH>... [SWITCH <STRING|ARRAY|INTEGER>]...\n\
#  @PID: Process ID\n\
#  	Integer 		The process id to attach to.\n\
#  @SWITCH: Parameter switches.\n\
#  	-h,--help 		This help message.\n\
#  	-f,--frames		STRING or ARRAY of animation frames.\n\
#  	-p,--prepend		STRING to prepend to spinner.\n\
#  	-a,--append		STRING to append to spinner.\n\
#  	-s,--spread		Time in INTEGER seconds to spread frames over.\n\n\
# "
# 	case "$1" in
# 		(-[Hh]|--[Hh][Ee][Ll][Pp]) printf "$help"
# 		return;;
# 		*) arg1="$1"
# 		shift;;
# 	esac
#     if [ "$(ps a | awk '{print $1}' | grep $arg1)" > /dev/null 2>&1 ]; then
#         local frame array pre app spread arg_i tmp
# 		if [ $# -gt 0 ]; then
#             if [[ "$1" =~ $hrx ]] || \
#                 [[ "$2" =~ $hrx ]]; then
#                 printf "$help"
#                 return
#             fi
# 			for arg_i in "$@"; do
# 				if [[ $1 =~ ^-[Pp]|--[Pp][Rr][Ee][Pp][Ee][Nn][Dd]$ ]]; then
# 					pre="$2"
# 					shift 2
# 				fi
# 				if [[ $1 =~ ^-[Aa]|--[Aa][Pp][Pp][Ee][Nn][Dd]$ ]]; then
# 					app="$2"
# 					shift 2
# 				fi
# 				if [[ $1 =~ ^-[Ff]|--[Fr][Rr][Aa][Mm][Ee][Ss]$ ]]; then
# 					IFS=',' read -r -a array <<< $2
# 					shift 2
# 					IFS=$oldIFS
# 				fi
# 				if [[ $1 =~ ^-[Ss]|--[Ss][Pp][Rr][Ee][Aa][Dd]$ ]]; then
# 					spread="$2"
# 					shift 2
# 				fi
# 			done
# 		fi
# 		if [[ -z  "$pre" ]]; then
# 			pre=""
# 		fi
# 		if [[ -z  "$app" ]]; then
# 			app=""
# 		fi
# 		if [[ -z  "$spread" ]]; then
# 			spread=1
# 		fi
# 		if [[ "${#array[@]}" -lt 1 ]]; then
# 			array=('' '' '' '' '' '' '' '' '' '' '' \
# 				'' '' '' '' '' '' '' '' '' '' '' '' '' '')
# 		fi
# 		while [ "$(ps a | awk '{print $1}' | grep $arg1)" > /dev/null 2>&1 ]; do
# 			for frame in "${array[@]}"; do
# 				printf "\r${pre}\e[92m${frame}\e[0m${app}"
# 				sleep "$(echo "$spread / ${#array[@]}" | bc -l)"
# 				printf "\r"
# 			done
# 		done
# 		printf "\n"
# 	else
# 		return 2
#     fi
# }
checkbash(){
	if [ -f "$*" ]; then
		checkbashism "$*" 2>/dev/null
		return
	fi
	return 1
}
findf(){
	local dir
	if [  $# -eq 0 ]; then
		dir="$(realpath .)"
	else
		if [ -d "$1" ]; then
			dir="$(realpath "$1")"
			shift
		fi
	fi
	eval find "$dir" "$*"
}
function from_pipe(){
	local from_pipe
	while read -r from_pipe; do
		printf "%s" "$from_pipe"
	done
}
function printff(){
	if [[ $# -gt 0 ]]; then
		eval printf "$@"
	else
		local string
		while read string; do
			echo -e "${string}"
		done
	fi
}
function ps1pipe(){
	local from_pipe item cnt=0
#	if [ $# -eq 1 ]; then
#		local delim="$*"

#	fi
	if [ $# -ge 1 ]; then
		local delim=true
	fi
	if [[ -n $delim ]]; then
		readarray from_pipe
	else
		read -a from_pipe
	fi
	for item in "${from_pipe[@]}"; do
		printf '%s' "${item}"
	done
}
function ps1pipe2(){
	local from_pipe
	if [ $# -gt 0 ]; then
		local delim="$*"
	fi
	while read -r from_pipe; do
		printf '%s' "${from_pipe}"
	done
}
function mailinator(){
	local phrase
	read phrase &&
	xdg-open 'https://'\
'www.mailinator.com/v3/index.'\
'jsp?zone=public&query='\
"$phrase"'#/#inboxpane'
}
#function red(){
#	local input delim=' ' red=$(echo -en "\033[91m") rst=$(tput sgr0)
#	if [[ $# -gt 0 ]]; then
#		delim="$*"
#	fi
#	while read -r input; do
#		printf "%s${delim}" "${red}${input}${rst}"
#	done
#}
function count_pipe_items(){
	local count=0
	while read input; do
		count=$(($count + 1))
	done
	echo -e "Piped item count: \e[32m$count\e[0m"
}
function update_glimpse(){
	which axel 2>&1 > /dev/null || return 1
	local url="https://github.com/glimpse-editor\
/Glimpse/releases/download/continuous/Glimpse_Image_\
Editor-4.git-615532d-x86_64.AppImage"
	local ai="/home/flux/Applications/Glimpse-Im\
age-Editor.AppImage"
	local ain="${ai}.new"
	[ -f "${ain}" ] && rm "${ain}"
	axel "${url}" -o "${ain}" || return 2
	cp "${ain}" "${ai}" || return 3
	[ -f "${ain}" ] && rm "${ain}"
	chmod u+x "${ai}"
}

function read_xi(){
	if [[ ! -t 0 ]]; then
		local input button state xpos ypos xstate ystate
		while read -r -a input; do
			if [[ "${input[0]}" == "button" ]]; then
				case "${input[1]}" in
					press) state="pressed";;
					*) state="released";;
				esac
				case "${input[2]}" in
					1) button="Left";;
					2) button="Middle";;
					3) button="Right";;
					4) button="Scroll Up";;
					5) button="Scroll Down";;
					8) button="XButton1";;
					9) button="XButton2";;
					*) button="Unknown";;
				esac
				printf '\nMouse Button: \033[1;33m%s\033[0m is \033[1;32m%s\033[0m.\n' "${button}" "${state}"
			fi
			if [[ "${input[0]}" == "motion" ]]; then
				if [[ -n "${input[2]}" ]]; then
					xpos="${input[1]:5}"
					ypos="${input[2]:5}"
					xstate="Moved"
					ystate="${xstate}"
				else
					if [[ "${input[1]:2:1}" -eq 0 ]]; then
						xpos="${input[1]:5}"
						ypos="${ypos}"
						xstate="Moved"
						ystate="Unmoved"
					else
						xpos="${xpos}"
						ypos="${input[1]:5}"
						xstate="Unmoved"
						ystate="Moved"
					fi
				fi
					printf '\nMouse State: \033[1;33mX\033[0m - \033[1;32m%s\033[0m, \033[1;33mY\033[0m - \033[1;32m%s\033[0m\n' "${xstate}" "${ystate}"
					printf 'Mouse Position: \033[1;33mX\033[1;32m%s\033[0m, \033[1;33mY\033[1;32m%s\033[0m\n' "${xpos}" "${ypos}"
			fi
		done
	fi
}
## "'
##
#function backup(){
#	[[ $# -gt 0 ]] || return 1
#	[[ -f "$*" ]] ||
#	[[ -d "$*" ]] || return 2
#	cp -rf "$*" "$*~"
#}
#function lsusers(){
#	local array
#	array=($(awk -F':' '{print $1}' /etc/passwd))
#	printf '%s ' "${array[@]}"
#}
#function git-create(){
#	[[ $# -lt 2 ]] && return 1
#	local rl='https://api.github.com/user/repos'
#	local un rn pv item de fn idxa=0
#	for item in "$@"; do
#		idxa=$(($idxa + 1))
#		case "${item}" in
#			-[pP])	pv=true
#				shift;;
#			-[uU]=*|--[uU][sS][eE][rR]=*) un="${item//-[uU]=/}"
#				un="${un//--[uU][sS][eE][rR]=/}"
#				shift;;
#			-[nN]=*|--[nN][aA][mM][eE]=*) rn="${item//-[nN]=/}"
#				rn="${rn//--[nN][aA][mM][eE]=/}"
#				shift;;
#			-[dD]=*|--[dD][eE][sS][cC]=*) de="${item//-[dD]=/}"
#				de="${de//--[dD][eE][sS][cC]=/}"
#				shift;;
#			*) return 2;;
#		esac
#	done
#	[[ -z "$pv" ]] && pv=false
#	[[ -z "$un" ]] && return 3
#	[[ -z "$rn" ]] && return 4
#	fn="${rn// /-}"
#	curl -u "${un}" "${rl}" -d \
#"{\"name\":\"${rn}\",\"private\":\"${pv}\",\"description\":\"${de}\"}" &&
#	echo "git clone https://github.com/${un}/${fn}.git"
#}
function a_remove_at(){
	[[ $# -lt 2 ]] && return 1
	local index=$1 iter array idx=0
	shift
	if [[ ! $index =~ ^[0-9]+$ ]]; then
		echo "$@"
		return 2
	fi
	for iter in "$@"; do
		if [[ $idx -ne "$index" ]]; then
			array+=($iter)
		fi
		idx=$(($idx + 1))
	done
	echo "${array[@]}"
}
function a_pop(){
	[[ $# -eq 0 ]] && return 1
	local iter array idx=0
	for iter in "$@"; do
		idx=$(($idx + 1))
		if [[ $# -gt $idx ]]; then
			array+=($iter)
		fi
	done
	echo "${array[@]}"
}
function a_push(){
	[[ $# -eq 0 ]] && return 1
	local iter array idx=0
	for iter in "$@"; do
		idx=$(($idx + 1))
		if [[ $idx -gt 1 ]]; then
			array+=($iter)
		fi
	done
	echo "${array[@]}"
}
function tapo(){
	[[ $# -eq 0 ]] && return 1
	local iter array idx=0
	for iter in "$@"; do
		if [[ $(($idx % 2)) -eq 0 ]]; then
			case "${iter}" in
				-[uU]|--[uU][sS][eE][rR]) un="${args[$index + 1]}";;
				-[nN]|--[nN][aA][mM][eE]) rn="${args[$index + 1]}";;
				-[dD]|--[dD][eE][sS][cC]) de="${args[$index + 1]}";;
				*) return $((4 + $idx));;
			esac
		fi
		idx=$(($idx + 1))
	done
	#echo "${array[@]}"
}
function guakeopen(){
	local params
	params=(
		--path='.'
		--title='Guake Open'
		--text='Open a 📝 or 📁:'
		--width=640
		--height=480
	)
	zen-list-run "${params[@]}"
}
for file in "${HOME}"'/.bash/profile/'*'.bash'; do . "${file}"; done
unset file
#function _gtk_theme(){
#	[[ $# -lt 2 ]] && return 1
#	local GTK_THEME="$1";shift
#	GTK_THEME="${GTK_THEME}" "$@"
#}
function _gtk_theme(){
	[[ $# -lt 2 ]] && return 1
	local GTK_THEME="$1";shift
	GTK_THEME="${GTK_THEME}" "$@"
}
function _get_pid_env(){
    if [[ $(id -u) -ne 0 ]]; then
        sudo bash -c ". $BASH_SOURCE && $FUNCNAME $*"
        return $?
    fi
    local pid input
    if [[ ! -t 0 ]]; then
        read -a input
        pid=${input[0]}
    else
        pid=$1
    fi
    [[ "${pid}" =~ ^[0-9]+$ ]] || return 1
    local env="$(tr -d '\0'  2>/dev/null < /proc/${pid}/environ)" err=$(($? + 1))
    [[ $err -gt 1 ]] && return $err
    printf '%s\n' "${env}"
}
function ty(){
    if [[ ! -t 0 ]]; then
        local input
        read -a input
        printf '%s\n' "${input[0]}"
    fi
}
function _to_array {
    local _array
    if [[ ! -t 0 ]]; then
        local _input
        while IFS= read -r _input; do
            _array+=("${_input}")
        done
    else
        if [[ $# -gt 0 ]]; then
            _array=($@)
        fi
    fi
    if [[ "${#_array[@]}" -gt 0 ]]; then
        printf '%s ' "${_array[@]}"
    fi
}
function red {
    if [[ ! -t 0 ]]; then
        local _input
        while IFS= read -r _input; do
            printf '\033[31m%s\033[0m\n' "${_input}"
        done
    fi
}
function randcol {
    if [[ ! -t 0 ]]; then
        local _input _rand
        while IFS=$(echo -en "\n\b") read -r _input; do
            _rand=($(shuf -i 31-36 -n 1) $(shuf -i 91-96 -n 1))
            printf '\033['"${_rand[$(shuf -i 0-1 -n 1)]}"'m%s\033[0m\n' "${_input}"
        done
    fi
}
##  \"\"
function e64 { base64 <<< "$*"; }
function d64 { base64 -d <<< "$*"; }
function _strlen { printf '%s' "$@" | wc -c; }
function _return {
    which xdotool 2>&1 > /dev/null || return 1
    xdotool key Return || return 2
}
complete -F _return exit
function _rand_single_int { printf '%s' "$(shuf -i 0-9 -n 1)"; }
#function _rand_color_int {
#    local _range=($(shuf -n ))
#}
function _rand_from_range {
    local _item _rand _item_count=0
    for _item in "$@"; do
        _item_count=$((_item_count + 1))
        [[ "${_item}" =~ ^[0-9]+$ ]] ||
        return ${_item_count}
    done
    printf '%s' "$(shuf -i $1-$2 -n 1)"
}
function apt-install {
    local _pkgs=$(
        zenity \
            --forms \
            --title="Install Apt Packges" \
            --text="Enter packages delimited by spaces:" \
            --add-entry="Packages" \
            --width=360
    )
    if [[ -n "${_pkgs}" ]]; then
        eval sudo apt install ${_pkgs} -y
        return $?
    fi
}
function uniq_in_array {
    local array=("${@:1:$(($# - 1))}")
    printf '%s\n%s\n' "${array[@]}" |
        grep -xq "${@:$#:1}"
}
function red {
    if [[ ! -t 0 ]]; then
        local oifs=$IFS stdin \
            red=$(echo -en "\033[91m") \
            rst=$(tput sgr0)
        IFS=''
        while read -r stdin; do
            printf "${red}%s${rst}\n" "${stdin}"
        done
        IFS=$oifs
    fi
}
function uline {
    if [[ ! -t 0 ]]; then
        local oifs=$IFS stdin \
            ul=$(echo -en "\033[4m") \
            rst=$(tput sgr0)
        IFS=''
        while read -r stdin; do
            printf "${ul}%s${rst}\n" "$(expand <<< $stdin)"
        done
        IFS=$oifs
    fi
}
function color_pipe(){
	if [[ ! -t 0 ]]; then
		local input colors='0' oifs=$IFS
		if [[ $# -gt 0 ]]; then
			local val index=0 string
			local range=($(seq 1 5) $(seq 30 37) $(seq 40 47) $(seq 90 97) $(seq 100 107))
			for val in "$@"; do
				case "${range[@]}" in
					*${val}*);;
					*) return 1;;
				esac
				index=$(($index + 1))
				if [[ $index -gt 1 ]]; then
					string="${string};${val}"
				else
					string="${val}"
				fi
			done
			colors="${string}"	
		fi
		IFS=''
		while read -r input; do
            printf "\033[${colors}m%s\033[0m\n" $(expand <<< $input)
		done
		IFS=$oifs
		return
	fi
}
#function file_link {
#    if [[ ! -t 0 ]]; then
#        local oifs=$IFS stdin \
#            ul=$(echo -en "\033[4m") \
#            rst=$(tput sgr0)
#        IFS=''
#        while read -r stdin; do
#            printf "${ul}file://%s${rst}\n" "$(expand <<< $stdin)"
#        done
#        IFS=$oifs
#    fi
#}
function str_range {
    if [[ ! -t 0 ]]; then
        local _oifs=$IFS _input _init _len
        if [[ $# -gt 0 ]]; then
            [[ $1 =~ ^[0-9]*$ ]] || return 1
            _init=$1
            if [[ $# -ge 2 ]]; then
                [[ $2 =~ ^[0-9]*$ ]] || return 2
                _len=$2
            fi
        fi
        [[ -z "${_init}" ]] && _init=0
        [[ -z "${_len}" ]] && _len=1
        while read -r _input; do
            echo "${_input:${_init}:${_len}}"
        done
        #IFS=$_oifs
    fi
}
function usap {
    printf  \
$(setcolors 1 5 91 40)'             \n     U'\
$(setcolors 97)'S'\
$(setcolors 94)'A     \n             \n'\
$(setcolors)
}
function trash {
    if [[ ! -t 0 ]]; then
        local input
        while IFS='' read -r input; do
            if [[ -f "${input}" ]]; then
                rm -f "${input}"
            fi
        done
    fi
}
function exe {
    if [[ ! -t 0 ]]; then
        local input
        while IFS='' read -r input; do
            [[ -f "${input}" ]] && chmod +x "${input}"
        done
    else
        [[ -f "$*" ]] && chmod +x "$@"
    fi
}
function sexe {
    if [[ ! -t 0 ]]; then
        local input
        while IFS='' read -r input; do
            [[ -f "${input}" ]] && sudo chmod +x "${input}"
        done
    else
        [[ -f "$*" ]] && sudo chmod +x "$@"
    fi
}
#function join_pipe {
#    if [[ ! -t 0 ]]; then
#        local delim suffix item string input_array
#    	for item in "$@"; do
#    		case "${item}" in
#    			-[dD]=*|--[dD][eE][lL][iI][mM]=*) delim="${item//-[dD]=/}"
#    				delim="${delim//--[dD][eE][lL][iI][mM]=/}"
#    				shift;;
#    			*) continue;;
#    		esac
#    	done
#        if [[ $# -ge 1 ]]; then
#            suffix="$@"
#        fi
#        if [[ "${delim}" == "" ]]; then
#            delim=','
#        fi
#        IFS=' ' read -r -a input_array
#        if [[ ${#input_array[@]} -eq 0 ]]; then
#            return 2
#        fi
#        if [[ "${suffix}" != "" ]]; then
#            string="${suffix}${delim}${input_array[@]/#/$delim}"
#        else
#            string="${input_array[@]}"
#        fi
#        printf "${string}"
#    else
#        return 1
#    fi
#}
function join {
    if [[ ! -t 0 ]]; then
        local delim item string input index=0
    	for item in "$@"; do
    		case "${item}" in
    			-[dD]=*|--[dD][eE][lL][iI][mM]=*) delim="${item//-[dD]=/}"
    				delim="${delim//--[dD][eE][lL][iI][mM]=/}"
    				shift;;
    			*) continue;;
    		esac
    	done
        if [[ "${delim}" == "" ]]; then
            delim=','
        fi
        while IFS='' read -r input; do
            if [[ $index -gt 0 ]]; then
                string="${string}${delim}${input}"
            else
                string="${input}"
            fi
            index=$((index+1))
        done
        printf '%s\n' "${string}"
    else
        return 1
    fi
}
function lsfiles {
    local path array IFS \
        rclr=($(shuf -i 31-36 -n 1) $(shuf -i 91-96 -n 1))
    rclr=${rclr[$(shuf -i 0-1 -n 1)]}
    if [[ $# -gt 0 ]]; then
        if [[ -d "$*" ]]; then
            path="$(realpath $@)"
        else
            return 1
        fi
    else
        path="$(realpath .)"
    fi
    IFS=$(echo -en "\n\b") array=($(ls -A ${path}))
    if [[ "${path}" =~ ^/$ ]]; then
        path=''
    fi
    printf "\e[4;37mfile://\e[${rclr}m${path}/%s\e[0m\n" "${array[@]}"
}
# function wow_toggle(){ printf '%s' 'wow: command not found'; }
function shellect { node .hyper_plugins/node_modules/hyper-shellect/run.js; }
function lsq {
    local directory
    if [[ ! -t 0 ]]; then
        local _input
        IFS='' read _input
        if [[ ! -d "$_input" ]] &&
            [[ ! -f "$_input" ]]; then
            return 1
        fi
        directory="$_input"
    fi
    if [[ $# -gt 0 ]]; then
        if [[ ! -d "$*" ]] &&
            [[ ! -f "$*" ]]; then
            return 2
        fi
        directory="$*"
    fi
    if [[ -z "$directory" ]]; then
        directory="."
    fi
    if [[ "${directory: -1}" == "/" ]]; then
        directory="${directory:: -1}"
    fi
    directory="${directory}/"
    printf "\e[2;32;107m %s \e[0m\n" "${directory}"*
}
function tmux-colors {
    for int in {0..255}; do
        print -Pn "%K{$int}  %k%F{$int}${(l:3::0:)int}%f " ${${(M)$((int%6)):#3}:+$'\n'}
    done
}
function reverse-order {
    if [ $# -eq 0 ]; then
        return 1
    fi
    local str_arr int str="$*" max_idx
    max_idx=$((${#str} - 1))
    for int in $(seq 0 $max_idx); do
        str_arr+=("${str:$(($max_idx - $int)):1}")
    done
    printf '%s' "${str_arr[@]}"
    printf '%s\n' ""
}
function debug_bash {
    printf '%s %s\n' \
        "Shell:" "$BASH_SUBSHELL" \
        "PID:" "$BASHPID" \
        "Source:" "$BASH_SOURCE" \
        "Line #:" "$BASH_LINENO" \
        "Options:" "$BASHOPTS" \
        "Completion Version:" "$BASH_COMPLETION_VERSINFO" \
        "ArgC:" "$BASH_ARGC" \
        "ArgV0:" "$BASH_ARGV0" \
        "Bash:" "$BASH" \
        "Version:" "$BASH_VERSION" \
        "Version Info:" "$BASH_VERSINFO"
}
# TODO "ArgV:" "${BASH_ARGV[@]}" \
# TODO Create functions for BASH_ALIASES & BASH_REMATCH
function iso_to_usb {
    if [ $# -lt 2 ]; then
        exit 1
    fi
    if [ -f "$1" ]; then
        if dd if="$1" of="$2" bs=512M; then
            sync
        fi
    fi
}
#function create_completion_list {
#    [ $# -lt 2 ] && return 1
#    local list=( $1 )
#    complete -W "$(printf '%s\n' "${list[@]}")" "$2" ||
#    return 2
#}
function kill_pipe {
    if [ ! -t 0 ]; then
        local input
        while IFS='' read -r input; do
            sudo kill -9 $input
        done
    fi
}
function len_pipe {
    if [ ! -t 0 ]; then
        local input
        while IFS='' read -r input; do
            printf 'Length of "%s": %d\n' "${input}" "${#input}"
        done
    fi
}
#function stat_pipe {
#    if [ ! -t 0 ]; then
#        local input
#        while IFS='' read -r input; do
#            stat "$input" 2>/dev/null
#        done
#    fi
#}
function type_pipe {
    if [ ! -t 0 ]; then
        local input stat
        while read -r input; do
            stat=$(stat -c %A "$input")
            stat=${stat:0:1}
            if [[ "$stat" == "d" ]]; then
                printf '"%s" is a directory.\n' "$input"
            else
                printf '"%s" is a file.\n' "$input"
            fi
        done
    fi
}
function cargor {
    local release
    if [[ $# -gt 0 ]]; then
        if [[ "$1" =~ ^-([rR]|-[rR][eE][lL][eE][aA][sS][eE])$ ]]; then
            release='--release'
        fi
    fi
    if [ ! -t 0 ]; then
        local input root="$PWD"
        while read -r input; do
            if [[ "$input" == *"Cargo.toml"* ]]; then
                cd "$(dirname "$(realpath "$input")")"
                eval cargo build $release
                cd "$root"
            fi
        done
    fi
}
function eval_pipe {
    if [[ ! -t 0 ]]; then
        local input
        while read -r input; do
            (eval "$input")
        done
    fi
}
function loadws {
    local array iter quiet=0
    IFS=$(echo -en "\n\b") array=($(ls --color=auto *".code-workspace" 2>/dev/null))
    if [[ ${#array[@]} -gt 0 ]]; then
        if [[ $# -gt 0 ]]; then
            if [[ "$1" =~ ^-([qQ]|-[qQ][uU][iI][eE][tT])$ ]]; then
                quiet=$(($quiet + 1))
            fi
        fi
        for iter in "${array[@]}"; do
            if [[ $quiet -eq 0 ]]; then
                printf 'Loading VSCode Workspace: %s\n' "${iter}"
            fi
            code "${iter}"
        done
    else return 1; fi
}
function replace {
    if [[ $# -lt 2 ]]; then
        return 1
    fi
    local input find="$1" repl="$2"
    shift 2
    if [[ ! -t 0 ]]; then
        while read -r input; do
            printf '%s\n' "${input//$find/$repl}"
        done
    else
        if [[ $# -gt 0 ]]; then
            for input in "$@"; do
                printf '%s\n' "${input//$find/$repl}"
            done
        else return 2; fi
    fi
}

#function oldest_file {
#    # TODO add passed argument usage
#    if [[ ! -t 0 ]]; then
#        local input array date iter index=0 lowest
#        declare -A array
#        while read -r input; do
#            if [[ -f "$input" ]]; then
#                date=$(stat -c %Z "$input")
#                array[$date]="$input"
#            fi
#        done
#        if [[ ${#array[@]} -eq 0 ]]; then
#            return 1
#        fi
#        for iter in "${!array[@]}"; do
#            if [[ $index -eq 0 ]]; then
#                index=$((index + 1))
#                lowest=$iter
#            fi
#            if [[ $iter -lt $lowest ]]; then
#                lowest=$iter
#            fi
#        done
#        lowest="${array[$lowest]}"
#        printf '\nOldest:\nFile:\t\t%s\nLast Changed:\t%s\n\n' \
#            $lowest "$(stat -c %z "$lowest")"
#    fi
#}
#function newest_file {
#    # TODO add passed argument usage
#    if [[ ! -t 0 ]]; then
#        local input array date iter index=0 highest
#        declare -A array
#        while read -r input; do
#            if [[ -f "$input" ]]; then
#                date=$(stat -c %Z "$input")
#                array[$date]="$input"
#            fi
#        done
#        if [[ ${#array[@]} -eq 0 ]]; then
#            return 1
#        fi
#        for iter in "${!array[@]}"; do
#            if [[ $index -eq 0 ]]; then
#                index=$((index + 1))
#                highest=$iter
#            fi
#            if [[ $iter -gt $highest ]]; then
#                highest=$iter
#            fi
#        done
#        highest="${array[$highest]}"
#        printf '\nNewest:\nFile:\t\t%s\nLast Changed:\t%s\n\n' \
#            $highest "$(stat -c %z "$highest")"
#    fi
#}
#function oldest_dir {
#    # TODO add passed argument usage
#    if [[ ! -t 0 ]]; then
#        local input array date iter index=0 lowest
#        declare -A array
#        while read -r input; do
#            if [[ -d "$input" ]]; then
#                date=$(stat -c %Z "$input")
#                array[$date]="$input"
#            fi
#        done
#        if [[ ${#array[@]} -eq 0 ]]; then
#            return 1
#        fi
#        for iter in "${!array[@]}"; do
#            if [[ $index -eq 0 ]]; then
#                index=$((index + 1))
#                lowest=$iter
#            fi
#            if [[ $iter -lt $lowest ]]; then
#                lowest=$iter
#            fi
#        done
#        lowest="${array[$lowest]}"
#        printf '\nOldest:\nDirectory:\t%s\nLast Changed:\t%s\n\n' \
#            $lowest "$(stat -c %z "$lowest")"
#    fi
#}
#function newest_dir {
#    # TODO add passed argument usage
#    if [[ ! -t 0 ]]; then
#        local input array date iter index=0 highest
#        declare -A array
#        while read -r input; do
#            if [[ -d "$input" ]]; then
#                date=$(stat -c %Z "$input")
#                array[$date]="$input"
#            fi
#        done
#        if [[ ${#array[@]} -eq 0 ]]; then
#            return 1
#        fi
#        for iter in "${!array[@]}"; do
#            if [[ $index -eq 0 ]]; then
#                index=$((index + 1))
#                highest=$iter
#            fi
#            if [[ $iter -gt $highest ]]; then
#                highest=$iter
#            fi
#        done
#        highest="${array[$highest]}"
#        printf '\nNewest:\nDirectory:\t%s\nLast Changed:\t%s\n\n' \
#            $highest "$(stat -c %z "$highest")"
#    fi
#}
#function cronstat {
#    local path_mode=1 time_mode=1 bare_mode=0 arg
#    if [[ $# -gt 0 ]]; then
#        for arg in "$@"; do
#            if [[ "$arg" =~ ^-([hH]|-[hH][eE][lL][pP])$ ]]; then
#                cat<<EOF
# 
# 'cronstat' - 'stat' wrapper to find the oldest
# and newest file, directory, or both from an
# arrayed or line delimited list.
# 
# @USAGE:
#    cronstat <LIST> [OPTIONS...]
#    <LIST> | cronstat [OPTIONS...]
# 
# @LIST:
#    Any arrayed list of files or directories
#    or the output of the 'find' or 'ls'
#    commands etc...
# 
# @OPTIONS:
#    -h,--help       This help screen.
#    -b,--bare       Print the path only, no
#                    extra information.
#    -f,--file       Filter by files.
#    -d,--directory  Filter by directories.
#                    Defaults to any file or
#                    directory.
#    -o,--oldest     Get the oldest item.
#                    Defaults to the newest.
# @EXAMPLES:
#    cronstat \$(find -maxdepth 1)
#    find -maxdepth 1 | cronstat
#    IFS=\$(echo -en "\n\b") array=(\$(ls -A --color=auto))
#    cronstat \${array[@]} --file
#    printf '%s\n' "\${array[@]}" | cronstat -odb
#
# @EXITCODES:
#    0               No errors.
#    1               No array or list passed.
#    2               No values in list.
# 
#EOF
#                return
#            fi
#            if [[ "$arg" =~ ^-([bB]|-[bB][aA][rR][eE])$ ]]; then
#                bare_mode=1
#                shift
#            fi
#            if [[ "$arg" =~ ^-([fF]|-[fF][iI][lL][eE])$ ]]; then
#                path_mode=2
#                shift
#            fi
#            if [[ "$arg" =~ ^-([dD]|-[dD][iI][rR][eE][cC][tT][oO][rR][yY])$ ]]; then
#                path_mode=3
#                shift
#            fi
#            if [[ "$arg" =~ ^-([oO]|-[oO][lL][dD][eE][sS][tT])$ ]]; then
#                time_mode=2
#                shift
#            fi
#            if [[ "$arg" =~ ^-([oO][fF]|[fF][oO])$ ]]; then
#                time_mode=2
#                path_mode=2
#                shift
#            fi
#            if [[ "$arg" =~ ^-([oO][dD]|[dD][oO])$ ]]; then
#                time_mode=2
#                path_mode=3
#                shift
#            fi
#            if [[ "$arg" =~ ^-([oO][bB]|[bB][oO])$ ]]; then
#                bare_mode=1
#                time_mode=2
#                shift
#            fi
#
#            if [[ "$arg" =~ ^-([fF][bB]|[bB][fF])$ ]]; then
#                bare_mode=1
#                path_mode=2
#                shift
#            fi
#            if [[ "$arg" =~ ^-([dD][bB]|[bB][dD])$ ]]; then
#                bare_mode=1
#                path_mode=3
#                shift
#            fi
#
#            if [[ "$arg" =~ ^-([oO][fF][bB]|[oO][bB][fF]|\
#                            [bB][oO][fF]|[bB][fF][oO]|\
#                            [fF][oO][bB]|[fF][bB][oO])$ ]]; then
#                bare_mode=1
#                time_mode=2
#                path_mode=2
#                shift
#            fi
#            if [[ "$arg" =~ ^-([oO][dD][bB]|[oO][bB][dD]|\
#                            [bB][oO][dD]|[bB][dD][oO]|\
#                            [dD][oO][bB]|[dD][bB][oO])$ ]]; then
#                bare_mode=1
#                time_mode=2
#                path_mode=3
#                shift
#            fi
#        done
#    fi
#    local input array date iter index=0 value time_string="Newest" path_string="File Or Directory"
#    declare -A array
#    if [[ ! -t 0 ]]; then
#        while read -r input; do
#            case "$path_mode" in
#                1)  if  [[ -f "$input" ]] ||
#                        [[ -d "$input" ]]; then
#                        date=$(stat -c %Z "$input")
#                        array[$date]="$input"
#                    fi;;
#                2)  if [[ -f "$input" ]]; then
#                        path_string="File"
#                        date=$(stat -c %Z "$input")
#                        array[$date]="$input"
#                    fi;;
#                3)  if [[ -d "$input" ]]; then
#                        path_string="Directory"
#                        date=$(stat -c %Z "$input")
#                        array[$date]="$input"
#                    fi;;
#            esac
#        done
#    else
#        if [[ $# -gt 0 ]]; then
#            for input in "$@"; do
#                case "$path_mode" in
#                    1)  if  [[ -f "$input" ]] ||
#                            [[ -d "$input" ]]; then
#                            date=$(stat -c %Z "$input")
#                            array[$date]="$input"
#                        fi;;
#                    2)  if [[ -f "$input" ]]; then
#                            path_string="File"
#                            date=$(stat -c %Z "$input")
#                            array[$date]="$input"
#                        fi;;
#                    3)  if [[ -d "$input" ]]; then
#                            path_string="Directory"
#                            date=$(stat -c %Z "$input")
#                            array[$date]="$input"
#                        fi;;
#                esac
#            done
#        else return 1; fi
#    fi
#    if [[ ${#array[@]} -eq 0 ]]; then
#         return 2
#    fi
#    for iter in "${!array[@]}"; do
#        if [[ $index -eq 0 ]]; then
#            index=$((index + 1))
#            value=$iter
#        fi
#        case "$time_mode" in
#            1)  if [[ $iter -gt $value ]]; then
#                    value=$iter
#                fi;;
#            2)  if [[ $iter -lt $value ]]; then
#                    time_string="Oldest"
#                    value=$iter
#                fi;;
#        esac
#    done
#    value="${array[$value]}"
#    if [[ $bare_mode -eq 0 ]]; then
#        printf '\n%s %s:\n%s\n\nLast Changed:\n%s\n\n' \
#            "$time_string" \
#            "$path_string" \
#            "$value" \
#            "$(stat -c %z "$value")"
#    else
#        printf '%s\n' "$value"
#    fi
#}
function setdot {
    local input array remove=0 needs_change=0
    for input in "$@"; do
        if [[ "$input" =~ ^-([rR]|-[rR][eE][mM][oO][vV][eE])$ ]]; then
            remove=1
        else
            array+=( "$input" )
        fi
    done
    if [[ ! -t 0 ]]; then
        while IFS=$(echo -en "\n\b") read -r input; do
            array+=( "$input" )
        done
    fi
    [[ ${#array[@]} -eq 0 ]] && return 1
    for input in "${array[@]}"; do
        if [[  -f "${input}" ]]; then
            local dir_name file_name
            dir_name="$(realpath $(dirname "$input"))"
            file_name="$(basename "$input")"
            if [[ $remove -eq 0 ]]; then
                if [[ "${file_name:0:1}" != "." ]]; then
                    needs_change=1
                    dot_name=".${file_name}"
                fi
            else
                if [[ "${file_name:0:1}" == "." ]]; then
                    needs_change=1
                    dot_name="${file_name/\./}"
                fi
            fi
            if [[ $needs_change -gt 0 ]]; then
                mv "${dir_name}/${file_name}" "${dir_name}/${dot_name}"
            fi
        fi
    done
}
function printu {
    local input
    if [[ ! -t 0 ]]; then
        while read -r input; do
            if [[ "$input" =~ ^[0-9a-fA-F]{4}$ ]]; then
                printf '%b\n' "\u$input"
            fi
        done
    else
        for input in "$@"; do
            if [[ "$input" =~ ^[0-9a-fA-F]{4}$ ]]; then
                printf '%b\n' "\u$input"
            fi
        done
    fi
}
function zenuni {
    local input=$(yad \
        --entry \
        --title="Unicode Hex Converter" \
        --text="Enter 1-8 hex digits:" \
        --geometry=360x64 \
        --no-buttons)
    if [[ "$input" =~ ^[0-9a-fA-F]{1,8}$ ]]; then
        printf '%b' "\U$input" | xclip -sel clip
    else return 1; fi
}
function id_from_title {
    if [[ $# -gt 0 ]]; then
        if !    wmctrl -l |
                grep -i "$@" |
                awk '{print $1}'; then
            return 2
        fi
    else return 1; fi
}
function toggle_shade_all {
    local title
    for title in $(wmctrl -l | awk '{print $4}'); do
        wmctrl -r "$title" -b toggle,shaded
    done
}
function bintodec {
    local input array args
    if [[ ! -t 0 ]]; then
        while read -r input; do
            args+=( "$input" )
        done
    else args=( "$@" ); fi
    if [[ ${#args} -eq 0 ]]; then return 1; fi
    for input in "${args[@]}"; do
        if [[ ! $input =~ ^[0-1]{1,8}$ ]]; then return 2; fi
        array+=( "$((2#$input))" )
    done
    printf '%s ' "${array[@]}"
    printf '%s\n' ""
}
function bintotxt {
    local input string args
    if [[ ! -t 0 ]]; then
        while read -r input; do
            args+=( "$input" )
        done
    else args=( "$@" ); fi
    if [[ ${#args} -eq 0 ]]; then return 1; fi
    for input in "${args[@]}"; do
        if [[ ! $input =~ ^[0-1]{1,8}$ ]]; then return 2; fi
        string+=( "$(printf "\x$(printf '%x' "$((2#$input))")")" )
    done
    printf '%s' "${string[@]}"
    printf '%s\n' ""
}
function empty_trash {
    local array input msg \
        trash="${HOME}/.local/share/Trash/files"
    for input in $(find ${trash} -maxdepth 1 2>/dev/null); do
        array+=( "$input" )
    done
    if [[ ${#array[@]} -gt 0 ]]; then
        if rm -rf "${array[@]}"; then msg="Trash emptied."
        else msg="Could not empty Trash."; fi
    else msg="No trash to empty."; fi
    printf '%s\n' "$msg"
}
function stat_pipe {
    if [ ! -t 0 ]; then
        local input
        while read -r input; do
            if  [ -f "$input" ] ||
                [ -d "$input" ]; then
                stat "$@" "$input"
            fi
        done
    else stat "$@"; fi
}
#function stat_pipe {
#    if [[ ! -t 0 ]]; then
#        local input
#        while read -r input; do
#            stat "$@" "$input"
#        done
#    else stat "$@"; fi
#}
function rm_pipe {
    if [[ ! -t 0 ]]; then
        local input input_user
        while read -r input; do
            if  [[ -f "$input" ]] ||
                [[ -d "$input" ]]; then
                printf 'Would you like to delete: %s: (y/[N])?\n' "$input"
                read -u 1 input_user
                if [[ "$input_user" =~ ^([yY]|[yY][eE][sS])$ ]]; then
                    rm "$@" "$input"
                fi
            fi
        done
    else rm "$@"; fi
}
function float_range {
    if [[ $# -ge 2 ]]; then
        local iter range num_a num_b
        for iter in "$@"; do
            if ! [[ "$iter" =~ ^[0-9]+$ ]]; then
                return 2
            fi
        done
        for num_a in $(seq $1 $2); do
            for num_b in {0..99}; do
                range+=( "${num_a}.$(printf '%02d' "$num_b")" )
                if [[ $num_a -eq $2 ]]; then break; fi
            done
        done
    else return 1; fi
    printf '%s\n' "${range[@]}"
}
function kill_else_oldest {
    local pids tmp arg_v max rev int
    if [[ ! -t 0 ]]; then
        read -a arg_v
    else arg_v=( "$@" ); fi
    [[ ${#arg_v[@]} -eq 0 ]] && return 1
    tmp=( $(pgrep ${arg_v[0]}) )
    [[ ${#tmp[@]} -eq 0 ]] && return 2
    max=$((${#tmp[@]} - 2))
    for ((int=$max;int>=0;int--)); do
        rev=$((max - $((max - int))))
        pids[rev]="${tmp[int]}"
    done
    if [[ ${#pids[@]} -eq 0 ]]; then
        return 3
    fi
    for tmp in "${pids[@]}"; do
        kill -9 $tmp
    done
}
function perms {
    local arg_v iter files perms
    if [[ ! -t 0 ]]; then
        read -a arg_v
    else arg_v=( "$@" ); fi
    [[ ${#arg_v[@]} -eq 0 ]] && return 1
    for iter in "${arg_v[@]}"; do
        if  [[ -f "$iter" ]] ||
            [[ -d "$iter" ]]; then
            files+=( "$iter" )
            perms+=( "$(stat -c %a $iter)" )
        fi
    done
    if  [[ ${#files[@]} -gt 0 ]] &&
        [[ ${#files[@]} -eq ${#perms[@]} ]]; then
        for iter in "${!files[@]}"; do
            printf '\e[1;93m%s\e[0m : \e[1;92;107m%s\e[0m\e[1;95;107m%s\e[0m\e[1;96;107m%s\e[0m\n' \
                "${files[iter]}" \
                "${perms[iter]:0:1}" \
                "${perms[iter]:1:1}" \
                "${perms[iter]:2:1}"
        done
    else return 2; fi
}
function join_by {
    if [[ $# -gt 0 ]]; then
        local IFS="$1"; shift;
    else return 1; fi
    local array input
    if [[ ! -t 0 ]]; then
        while read -r input; do
            array+=( $input )
        done
    else array=( $@ ); fi
    [[ ${#array[@]} -eq 0 ]] && return 2
    IFS=$IFS echo "${array[*]}"
}
function strip_color {
    local arg_v input iter IFS=$(echo -en "\n\b")
    if [[ ! -t 0 ]]; then
        while read -r input; do
            arg_v+=( $input )
        done
    else arg_v=( $@ ); fi
    [[ ${#arg_v[@]} -eq 0 ]] && return 1
    for iter in "${arg_v[@]}"; do
        sed "s/\x1B\[\([0-9]\{1,3\}\(;[0-9]\{1,3\}\)\+\?\)\?[mGK]//g" <<< "$iter"
    done
}
function esc_chars {
    local input tmp_array tmp \
        char_array IFS=$(echo -en "\n\b")
    if [ ! -t 0 ]; then
        while read -r input; do
            tmp_array+=( "$input" )
        done
    else tmp_array=( "$@" ); fi
    [[ ${#tmp_array[@]} -gt 0 ]] || return 1 
    for input in "${tmp_array[@]}"; do
        tmp=( $(printf '%s\n' "$input" | fold -w1) )
        char_array+=( $(printf '\%s' "${tmp[@]}") )
    done
    printf '%s\n' "${char_array[@]}"
}
function hex { 
    local args input \
        IFS=$(echo -en "\n\b")
    if [[ ! -t 0 ]]; then
        while read -r input; do
            args+=( "$input" )
        done
    else args=( "$@" ); fi
    if [[ ${#args} -gt 0 ]]; then
        for input in "${args[@]}"; do
            if [[ "$input" =~ ^[0-9]+$ ]]; then
                printf '%x\n' $input
            else return 2; fi
        done
    else return 1; fi
}
function datatoutf {
    if ! which iconv 2>&1>/dev/null; then return 1; fi
    if [[ $# -ge 2 ]]; then 
        if ! [[ -f "$1" ]]; then return 3; fi
    else return 2; fi
    if ! iconv -f ISO-8859-1 -t UTF-8//TRANSLIT "$1" -o "$2"; then
        return 4
    fi
}
function history_reduce {
    local hist_file="$HOME/.bash_history" \
        tmp_file="${hist_file}.tmp"
    if ! [[ -f "$hist_file" ]]; then return 1; fi
    datatoutf "$hist_file" "$tmp_file"
    onlyone "${tmp_file}" > "$hist_file"
}
#function split_chars {
#    local array IFS=$(echo -en "\n\b")
#    [ ! -t 0 ] && {
#        local input
#        while read -r input; do
#            array+=( "$input" )
#        done
#    } || array=( "$@" )
#    printf '%s' "${array[@]}" |
#        grep --color=never -o .
#}
