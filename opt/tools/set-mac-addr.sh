#!/bin/sh

THISDIR="$(dirname "$(realpath "${0}")")/"
export PATH="${THISDIR}:${PATH}"
. "${THISDIR}"/utils.sh

set -e -u

hex2mac() {
	MAC=""
	seq 2 2 12 | while read i
	do
		echo -n ${1} | head -c $i | tail -c 2
		if [ $i != 12 ]
		then
			echo -n ':'
		fi
	done | tr '[:upper:]' '[:lower:]'
}

INFO="${1}"
NAME=$(echo $INFO | awk -F'-' '{print $1}')
MAC0HEX=$(echo $INFO | awk -F'-' '{print $3}')
MAC1HEX=$(echo $MAC0HEX 1 | busybox dc -e '16o16i?+p')

if [ "$NAME" != "LM4A0" ]
then
	echo "BAD INPUT"
	exit 1
fi

MAC0=$(hex2mac $MAC0HEX)
MAC1=$(hex2mac $MAC1HEX)

echo "end0: $MAC0"
echo "end1: $MAC1"


FW_SETENV="$(which fw_setenv)"
FW_PRINTENV="$(which fw_printenv)"

if [ -z "${FW_SETENV}" ]
then
	echo "fw_setenv not found"
	exit 1
fi

if [ -z "${FW_PRINTENV}" ]
then
	echo "fw_printenv not found"
	exit 1
fi

FW_SETENV="${FW_SETENV} -c ${THISDIR}/fw_env.config"
FW_PRINTENV="${FW_PRINTENV} -c ${THISDIR}/fw_env.config"

${FW_SETENV} ethaddr $MAC0
${FW_SETENV} eth1addr $MAC1

${FW_PRINTENV} ethaddr
${FW_PRINTENV} eth1addr

# hostname with mac address
OLD_HOSTNAME=$(cat /etc/hostname)
NEW_HOSTNAME="lpi4a$(echo $MAC0 | tr -d ':\n' | tail -c 4)"

for file in /etc/hostname /etc/hosts
do
	sed -i -e "s/$OLD_HOSTNAME/$NEW_HOSTNAME/g" $file
done
nmcli general hostname "$NEW_HOSTNAME"
hostname "$NEW_HOSTNAME"

echo "mac address change ok"
