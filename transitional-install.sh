#!/bin/ash

if [ `whoami` != "root" ]; then
	echo "root privilege is required."
	exit 1
fi

TARGET_DEV=sdb1
ROOT_DEV=sdc1
TARGET=/dev/$TARGET_DEV
FST=ext3
MKFS=mkfs.$FST
TREE=/home/kamei/nnl-builder/target-tree
HOSTNAME=noname
DOMAINNAME=linux.name
IPADDRESS=192.168.0.6

##################################################################
## 0. format and install
$MKFS $TARGET
MNT=`mktemp -d /tmp/musl.XXXXXXXXXX`
mount $TARGET $MNT
cd $TREE
tar cf - . | ( cd $MNT; tar xvf -)

cd $MNT
chmod -v 664 var/run/utmp
chown -R root:root *


## 1. fstab
cat > etc/fstab << EOF
# Begin /etc/fstab

# file system  mount-point  type   options          dump  fsck
#                                                         order

/dev/$ROOT_DEV      /            $FST   defaults         1     1
proc           /proc        proc   defaults         0     0
sysfs          /sys         sysfs  defaults         0     0
devpts         /dev/pts     devpts gid=4,mode=620   0     0
shm            /dev/shm     tmpfs  defaults         0     0
# End /etc/fstab
EOF
cat etc/fstab


## 2. bootloader
# (snip)

# Here is the sample for existing CentOS6's grub2
KERNEL=`ls boot/vmlinuz-* | xargs basename`
TIMESTAMP=`date +"%Y%m%d%H%M%S"`
cp -av /boot/grub/grub.conf /boot/grub/grub.conf-$TIMESTAMP

cat >> /boot/grub/grub.conf <<EOF
title NoName Linux $TIMESTAMP
	root (hd1,0)
	kernel /boot/$KERNEL root=/dev/$ROOT_DEV raid=noautodetect
EOF
tail -n 3 /boot/grub/grub.conf

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
mknod dev/zero c 1 5
ls -l dev
cat etc/inittab
cd /root
tar xf /home/kamei/nnl-builder.tar.bz2 -C $MNT/root/
umount $MNT
echo "DONE"
