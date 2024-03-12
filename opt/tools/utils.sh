green() {
	echo -ne "\033[32m"
}

red() {
	echo -ne "\033[31m"
}

blue() {
	echo -ne "\033[34m"
}

nocolor() {
	echo -ne "\033[0m"
}

err_if_noset() {
	if [ -z "$(printenv "${1}")" ]
	then
		echo "${1}: ${2}"
		exit 1
	fi
}

set_if_noset() {
	if [ -z "$(printenv "${1}")" ]
	then
		export "${1}"="${2}"
	fi
}

err_if_not_found() {
	if [ ! -e "${1}" ]
	then
		echo "${1}: ${2}"
		exit 1
	fi
}

create_dir_if_not_found() {
	if [ ! -e "${1}" ]
	then
		mkdir -pv "${1}"
	fi
}

delete_if_found() {
	if [ -e "${1}" ]
	then
		rm -rf "${1}"
	fi
}
