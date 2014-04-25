#!/bin/ash

if [ `whoami` != "root" ]; then
	echo "root privilege is required."
	exit 1
fi

TIMESTAMP=`date +"%Y%m%d%H%M%S"`

TGT=nbd0
IMG_TGT=/dev/nbd0
IMG_ROOT=/dev/nbd0p2
IMG_SWAP=/dev/nbd0p1
IMG_TYPE=qcow2
#IMG_TYPE=raw
FS_TYPE=ext4
MKFS=mkfs.$FS_TYPE
MKSWAP=mkswap
BUILDER_ROOT=/home/kamei/nnl-builder
DEV_ROOT=/dev/vdc2
DEV_SWAP=/dev/vdc1
GRUB2_ROOT='(hd2,msdos2)'


HOSTNAME=noname
DOMAINNAME=linux.name
IPADDRESS=192.168.0.6


##################################################################
## 0. format and install

modprobe nbd max_part=16
qemu-nbd -v --disconnect $IMG_TGT 2>/dev/null

#qemu-img create -f qcow2 example.img 50G
#qemu-nbd --connect=$IMG_TGT `pwd`/example.img
#fdisk $TARGET
##     Device Boot      Start         End      Blocks   Id  System
##/dev/nbd0p1            2048     8390655     4194304   82  Linux swap / Solaris
##/dev/nbd0p2         8390656   104857599    48233472   83  Linux
#qemu-nbd -v --disconnect $IMG_TGT

cp -av example.img $HOSTNAME-$TIMESTAMP.img
qemu-nbd --connect=$IMG_TGT `pwd`/$HOSTNAME-$TIMESTAMP.img

$MKFS $IMG_ROOT
$MKSWAP $IMG_SWAP

MNT=`mktemp -d /tmp/musl.XXXXXXXXXX`
mount $IMG_ROOT $MNT && \
(
cd $BUILDER_ROOT/target-tree
tar cf - . | ( cd $MNT; tar xvf -)
)

(
cd $MNT
chmod -v 664 var/run/utmp
chown -R root:root *


## 1. fstab
cat > etc/fstab << EOF
# Begin /etc/fstab

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
cat etc/fstab


## 2. bootloader
# (snip)

if [ 0 ]; then

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

fi

## 3. hostname
# existing default is 'musl'
echo "$HOSTNAME" > etc/HOSTNAME
cat etc/HOSTNAME

## 4. hosts
cat > etc/hosts << EOF
# Begin /etc/hosts

127.0.0.1	localhost localhost4
::1		localhost localhost6
$IPADDRESS	$HOSTNAME.$DOMAINNAME	$HOSTNAME

# End /etc/hosts
EOF
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
mkdir dev/pts
mkdir dev/ptmx c 5 2
mknod dev/ram0 b 1 0
mknod dev/random c 1 8
mknod dev/sdb1 b 8 17
mknod dev/sdb2 b 8 18
mknod dev/sdc1 b 8 33
mknod dev/sr0 b 11 0
mknod dev/tty1 c 4 1
mknod dev/tty2 c 4 2
mknod dev/tty3 c 4 3
mknod dev/urandom c 1 9
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
mknod dev/zero c 1 5
ls -l dev
cat etc/inittab

mkdir -p root/nnl-builder
(
cd $BUILDER_ROOT
tar cf - . | ( cd $MNT/root/nnl-builder; tar xvf -)
)
echo "Removing useless files..."
rm -rf $MNT/root/nnl-builder/cross-tools
rm -rf $MNT/root/nnl-builder/target-tree
rm -rf $MNT/root/nnl-builder/build/*
)
echo "Unmounting..."
umount $MNT && qemu-nbd --disconnect $IMG_TGT
#mv nonoame-$TIMESTAMP.img /var/lib/libvirt/images/
echo "DONE"

rmdir -v $MNT
