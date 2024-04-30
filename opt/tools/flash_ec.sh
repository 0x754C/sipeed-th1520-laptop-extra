#!/bin/bash

set -x

THISDIR="$(dirname "$(realpath "${0}")")/"
export PATH="${THISDIR}:${PATH}"
. "${THISDIR}"/utils.sh

if (cat /proc/device-tree/model | grep -a LicheePocket4A);
then
	echo "LicheePocket4A ec flash is not support "
	sleep 65535
fi


FWDIR="${THISDIR}/../firmware"

if [ $(id -u) -ne 0 ]
then
	echo "please use root user execute this script"
	exit 1
fi

if [ -z "${2}" ]
then
	if (cat /proc/device-tree/model | grep -a LicheeConsole4A);
	then
		FW="${FWDIR}/ch58x-sipeed-ec-console4a.bin"
	elif (cat /proc/device-tree/model | grep -a Plastic)
	then
		FW="${FWDIR}/ch58x-sipeed-ec-14inch-plastic.bin"
	else
		FW="${FWDIR}/ch58x-sipeed-ec-14inch-metal.bin"
	fi
else
	FW="${2}"
fi

WCHISP=$(which wchisp)

if [ -z "${WCHISP}" ]
then
	echo "wchisp not found"
	exit 1
fi

# if dc-charger gpio is not 432, you need recompute it
# GPIO0_16 432 (dc-charger)
# GPIO0_24 440
# GPIO0_25 441
EC_BOOT="440"

echo $EC_BOOT > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio$EC_BOOT/direction

boot_high() {
	echo 1 > /sys/class/gpio/gpio$EC_BOOT/value
}

boot_low() {
	echo 0 > /sys/class/gpio/gpio$EC_BOOT/value
}

boot_high
sleep 13
${WCHISP} config reset
CONFIG_RET="${?}"
${WCHISP} flash "${FW}"
boot_low

if [ "$CONFIG_RET" = "0" ]
then
	green
	echo "ec flash done"
	echo "ec 烧录成功"
	nocolor
	sleep 100000
	exit 0
else
	echo "ec flash failed"
	echo "try other method"
	echo "ec 烧录失败，尝试另一种烧录方法"
fi

# GPIO0_16 432 (dc-charger)
# GPIO0_24 440
# GPIO0_25 441
EC_RST="441"

echo $EC_RST > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio$EC_RST/direction

rst_high() {
	echo 0 > /sys/class/gpio/gpio$EC_RST/value
}

rst_low() {
	echo 1 > /sys/class/gpio/gpio$EC_RST/value
}

echo "ec flash method: first"
boot_high
sleep 0.5
boot_low
sleep 0.5
rst_low
sleep 0.5
rst_high
sleep 0.5
boot_high
${WCHISP} config reset
CONFIG_RET="$?"
${WCHISP} flash "${FW}"
boot_low

if [ "$CONFIG_RET" = "0" ]
then
	green
	echo "ec flash done"
	echo "ec 烧录成功"
	nocolor
else
	red
	echo "ec flash failed"
	echo "ec 烧录失败"
	nocolor
fi
sleep 10000
exit 0
