#!/bin/ash

if [ "x$TREE_TGT" == "x" ]; then
	echo "It cannot be run individually!"
	exit 1
fi
if [ `whoami` != "root" ]; then
	echo "root privilege is required."
	exit 1
fi
if [ "x$1" == "x" ]; then
	echo "usage: config-tree.sh <target-root>"
	exit 1
fi
if [ ! -f $1/boot/vmlinuz ]; then
	echo "$1/boot/vmlinuz is not found!"
	exit 1
fi

cd $1 && pwd

chmod -v 664 var/run/utmp
chown -R root:root *


## 1. fstab
if [ $TREE_TGT != "cdrom" ]; then
cat > etc/fstab << EOF
# Begin /etc/fstab for $TREE_TGT

# file system  mount-point  type   options          dump  fsck
#                                                         order

$DEV_ROOT      /            $FS_TYPE   defaults         1     1
$DEV_SWAP      swap         swap    pri=1         0     0
proc           /proc        proc   defaults         0     0
sysfs          /sys         sysfs  defaults         0     0
devpts         /dev/pts     devpts gid=4,mode=620   0     0
shm            /dev/shm     tmpfs  defaults         0     0
# End /etc/fstab
EOF
else
cat > etc/fstab << EOF
# Begin /etc/fstab for $TREE_TGT

# file system  mount-point  type   options          dump  fsck
#                                                         order

$DEV_ROOT     /            $FS_TYPE   defaults      0     0
proc           /proc        proc   defaults         0     0
sysfs          /sys         sysfs  defaults         0     0
devpts         /dev/pts     devpts gid=4,mode=620   0     0
shm            /dev/shm     tmpfs  defaults         0     0
# End /etc/fstab
EOF
fi
cat etc/fstab


## 2. bootloader
# (snip)

case "$TREE_TGT" in
neighborhood)
echo "#### For a neighborhood HDD in the same machine ####"

KERNEL=`ls boot/vmlinuz-* | xargs basename`
# CentOS6
if [ -f /boot/grub/grub.conf ]; then
	cp -av /boot/grub/grub.conf /boot/grub/grub.conf-$TIMESTAMP-backup

	cat >> /boot/grub/grub.conf <<EOF
title NoName Linux $TIMESTAMP
	root (hd1,0)
	kernel /boot/$KERNEL root=$DEV_ROOT raid=noautodetect
EOF
	tail -n 3 /boot/grub/grub.conf
fi
# Fedora19
if [ -f /boot/grub2/grub.cfg ]; then
	if [ -f /boot/grub2/custom.cfg ]; then
		cp -av /boot/grub2/custom.cfg /boot/grub2/custom.cfg-$TIMESTAMP-backup
	fi
	
	cat >> /boot/grub2/custom.cfg <<EOF
menuentry 'NoName Linux $TIMESTAMP' --class gnu-linux --class gnu --class os {
	load_video
	set gfxpayload=keep
	insmod gzio
	insmod part_msdos
	insmod ext2
	set root=$GRUB2_ROOT
	linux /boot/$KERNEL root=$DEV_ROOT raid=noautodetect vconsole.keymap=jp106
	}
EOF
fi
#### End of neighborhood ####
;;
cdrom)
echo "#### For a bootable CD-ROM image in the same machine ####"
mv boot isolinux && ln -s isolinux boot
# ISOLINUX.CFG
cat > isolinux/isolinux.cfg <<EOF
timeout 5
default linux
label linux
kernel vmlinuz
append ro root=$DEV_ROOT vga=ask
EOF
mv usr/share/syslinux/isolinux.bin isolinux/isolinux.bin && \
ln -s /isolinux/isolinux.bin usr/share/syslinux/isolinux.bin
#### End of bootable CD-ROM ####
;;
*)
echo "Boot configuration is skipped."
;;
esac


## 3. hostname
# existing default is 'musl'
echo "$HOSTNAME" > etc/HOSTNAME
echo "#### ETC/HOSTNAME ####"
cat etc/HOSTNAME

## 4. hosts
if [ "x$IPADDRESS" != "x" ]; then
echo "#### ETC/HOSTS for $IPADDRESS ####"
cat > etc/hosts << EOF
# Begin /etc/hosts

127.0.0.1	localhost localhost4
::1		localhost localhost6
$IPADDRESS	$HOSTNAME.$DOMAINNAME	$HOSTNAME

# End /etc/hosts
EOF
else
echo "#### ETC/HOSTS for localhost ####"
cat > etc/hosts << EOF
# Begin /etc/hosts

127.0.0.1	localhost localhost4	$HOSTNAME
::1		localhost localhost6	$HOSTNAME

# End /etc/hosts
EOF
fi
cat etc/hosts

## XXX FIXME XXX
mknod dev/console	c 5 1
chmod 600 dev/console
ln -s sr0 dev/cdrom
ln -s sr0 dev/cdrw
ln -s sr0 dev/dvd
ln -s sr0 dev/dvdrw
mknod dev/fb0 c 29 0
mknod dev/loop0 b 7 0
mknod dev/null c 1 3
mknod dev/ptmx c 5 2
mkdir dev/pts
mknod dev/ram0 b 1 0
mknod dev/random c 1 8
mknod dev/sdb1 b 8 17
mknod dev/sdb2 b 8 18
mknod dev/sdc1 b 8 33
mkdir dev/shm
chmod 1777 dev/shm
mknod dev/sr0 b 11 0
mknod dev/tty1 c 4 1
mknod dev/tty2 c 4 2
mknod dev/tty3 c 4 3
mknod dev/urandom c 1 9
mknod dev/zero c 1 5

mknod dev/vda b 253 0
mknod dev/vda1 b 253 1
mknod dev/vda2 b 253 2
mknod dev/vda5 b 253 5
mknod dev/vdb b 253 16
mknod dev/vdb1 b 253 17
mknod dev/vdb2 b 253 18
mknod dev/vdc b 253 32
mknod dev/vdc1 b 253 33
mknod dev/vdc2 b 253 34

echo "#### DEVICES ####"
ls -l dev
echo "#### ETC/INITTAB ####"
cat etc/inittab

echo ""
