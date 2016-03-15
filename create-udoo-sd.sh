#!/bin/sh -e

#
# Create a UDOO Quad SD card
#
# Depends on:
#  A terminal-based tool for monitoring the progress of data through a pipeline.
#   pacman -S pv
#  A network utility to retrieve files from the Web
#   pacman -S wget
#

# Using the latest arch linux tar ball version
root_filename=ArchLinuxARM-armv7-latest.tar.gz
# Bootloader filename for UDOO Quad
bootloader_filename=u-boot-quad.imx

if [[ $# -eq 0 ]] ; then
	echo "usage: $0 device-name [dual|quad]"
	echo "device name is something like /dev/sdX"
	echo "the second parameter is optional, the default is quad"
	echo "Warning! All data in the device will be lost!"
	echo "Chose one of the devices available:"
	lsblk
	exit 0
fi

if [[ "$2" = dual ]] ; then
	bootloader_filename=u-boot-dual.imx
fi

hdd=$1

echo Create UDOO Quad SD in $hdd

echo Zero the SD start
dd if=/dev/zero of=$hdd bs=1M count=8

echo Partition SD card
# Clear all partitions, create single new partition starting in 8192
echo "o
n
p
1
8192

w
"|fdisk $hdd

fdisk -l $hdd

echo Create the ext4 file system
yes | mkfs.ext4 ${hdd}1

if [ ! -f $root_filename ]; then
	echo "Get root file system tar ball from archlinuxarm"
	wget http://archlinuxarm.org/os/$root_filename
fi

echo Create local mnt dir if necessary and mount new SD file system
mkdir -p mnt
mount ${hdd}1 mnt

echo Extract root file system into new file system
pv $root_filename | bsdtar -xpf - -C mnt
sync
echo Unmount SD file system
umount mnt

if [ ! -f $bootloader_filename ]; then
	echo "Get u-boot bootloader from archlinuxarm"
	wget http://archlinuxarm.org/os/imx6/boot/udoo/$bootloader_filename
fi

echo Install the U-Boot bootloader
dd if=$bootloader_filename of=$hdd bs=512 seek=2
sync

echo New UDOO Quad SD created!
echo Root file system: $root_filename
echo Bootloader: $bootloader_filename
