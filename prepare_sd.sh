#!/usr/bin/env bash
# $1=/dev/sdX sdcard
if [[ ! $1 ]] || [[ ! $2 ]]; then
	echo "Usage:$0 </dev/sdX> <kernel_dir>"
	exit 1
fi
DIR=$(pwd)
BUILDROOT=$DIR/buildroot-allwinner
echo "$(date)" >> prepare_sd.log
echo "Unmount partitios $1(1/2)"
mounted=$(mount | grep ${1}1)
if [ "${mounted}" ]; then
	echo "Umount ${1}1"
	sudo umount ${1}1 >> prepare_sd.log
	if [ $? -ne 0 ]; then
		echo "Failed to umount ${1}1"
		exit 1
	fi
fi
mounted=$(mount | grep ${1}2)
if [ "${mounted}" ]; then
	echo "Umount ${1}2"
	sudo umount ${1}2 >> prepare_sd.log
	if [ $? -ne 0 ]; then
		echo "Failed to umount ${1}2"
		exit 1
	fi
fi
echo "Delete Existing Partition Table"
sudo dd if=/dev/zero of=$1 bs=1M count=1 >> prepare_sd.log
echo "Creating Partitions"
sudo parted $1 --script mklabel msdos >> prepare_sd.log
if [ $? -ne 0 ]; then
	echo "Failed to create label for $1"
	exit 1
fi
echo "Partition 1 - ${1}1"
sudo parted $1 --script mkpart primary fat32 2048s 16MB >> prepare_sd.log
if [ $? -ne 0 ]; then
	echo "Failed to create ${1}1 partition"
	exit 1
fi
vfat_end=$(sudo fdisk -lu ${1} | grep ${1}1 | awk '{print $3}')
ext4_offset=$(expr ${vfat_end} + 1)
echo "Partition 2 (Starts at sector No. ${ext4_offset})"
sudo parted $1 --script mkpart primary ext4 ${ext4_offset}s -- -1 >> prepare_sd.log
if [ $? -ne 0 ]; then
	echo "Failed to create ${1}2 partition"
	exit 1
fi
sync;sync
echo "Format Partition 1 to VFAT"
mkfs.vfat ${1}1 >> prepare_sd.log
if [ $? -ne 0 ]; then
	echo "Failed to format ${1}1 partition"
	exit 1
fi
echo "Format Partition 2 to EXT-4"
sudo mkfs.ext4 ${1}2 >> prepare_sd.log
if [ $? -ne 0 ]; then
	echo "Failed to format ${1}2 partition"
	exit 1
fi
sync;sync
echo "Copy sunxi-spl.bin loader"
dd if=$DIR/output/sunxi-spl.bin of=$1 bs=1024 seek=8 >> prepare_sd.log
echo "Copy u-boot.bin"
dd if=$DIR/output/u-boot.bin of=$1 bs=1024 seek=32 >> prepare_sd.log
echo "Copy uZimage, script.bin and boot.scr"
mkdir -p $DIR/tmp/part1 >> prepare_sd.log
sudo mount ${1}1 $DIR/tmp/part1 >> prepare_sd.log
if [ $? -ne 0 ]; then
	echo "Failed to mount ${1}1 partition"
	exit 1
fi
if [ -e $DIR/output/$2/uImage ]; then
	sudo cp -v $DIR/output/$2/uImage $DIR/tmp/part1 >> prepare_sd.log
else
	echo "uImage not exist."
	exit 1
fi
if [ -e $DIR/output/script.bin ]; then
	sudo cp -v $DIR/output/script.bin $DIR/tmp/part1 >> prepare_sd.log
else
	echo "script.bin not exist."
	exit 1
fi
if [ -e $DIR/uboot/boot.scr ]; then
	sudo cp -v $DIR/uboot/boot.scr $DIR/tmp/part1 >> prepare_sd.log
else
	echo "boot.scr not exist."
	exit 1
fi
echo "Copy rootfs on ${1}2 Partition"
mkdir -p $DIR/tmp/part2 >> prepare_sd.log
sudo mount ${1}2 $DIR/tmp/part2 >> prepare_sd.log
if [ $? -ne 0 ]; then
	echo "Failed to mount ${1}2 partition"
	exit 1
fi
if [ -e $BUILDROOT/output/images/rootfs.tar ]; then
	sudo tar -xf $BUILDROOT/output/images/rootfs.tar -C $DIR/tmp/part2 >> prepare_sd.log
else
	echo "rootfs.tar not exist."
	exit 1
fi
sync;sync
echo "Copy modules"
if [ -d $DIR/output/$2/lib/modules ]; then
	sudo cp -rvf $DIR/output/$2/lib $DIR/tmp/part2/ >> prepare_sd.log
else
	echo "modules not exist."
	exit 1
fi
echo "Unmount $1(1/2)"
sudo umount ${1}1 ${1}2
if [ $? -ne 0 ]; then
	echo "Failed to umount ${1}(1/2) partitions"
	exit 1
fi
rm -rvf $DIR/tmp
echo "Fatto" 
