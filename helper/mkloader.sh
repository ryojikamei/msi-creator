#!/bin/ash

if [ "x$2" == "x" ]; then
	echo "usage: mkloader.sh <filename> <mntpoint>"
	exit 1
fi
if [ ! -d "$2" ]; then
	echo "Directory $2 is not found!"
	exit 1
fi

RD_BS=1k
RD_COUNT=4096


dd if=/dev/zero of=$1 bs=$RD_BS count=$RD_COUNT
mkfs.ext2 -F -m 0 -b $RD_BS $1 $RD_COUNT
mount -o loop $1 $2
(
cd $2

# /dev
mkdir dev
mknod dev/console       c 5 1
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
mknod dev/sr0 b 11 0
mknod dev/tty1 c 4 1
mknod dev/tty2 c 4 2
mknod dev/tty3 c 4 3
mknod dev/urandom c 1 9
mknod dev/zero c 1 5

# virtual fs
mkdir proc
mkdir sys

# /root
mkdir root

# /bin & /sbin
mkdir bin && ln -s bin sbin

LIST=`opkg-cl files busybox | grep ^/`
for b in $LIST; do
	cp -av $b bin/
done

cp -v /usr/sbin/mkfs.ext4 bin/
ln -s mkfs.ext4 bin/mkfs.ext3
cp -v /usr/bin/dialog bin/

# /lib
mkdir lib
cp -v /lib/libc.so lib/
cp -av /lib/ld-musl-i386.so.1 lib/
cp -v /usr/lib/libgcc_s.so.1 lib/
cp -v /lib/libncursesw.so.5 lib/

# /var
mkdir var

# /etc
mkdir etc

cat > etc/fstab << EOF
/dev/root	/	ext2	defaults	0	0
proc		/proc	proc	defaults	0	0
sysfs		/sys	sysfs	defaults	0	0
devpts		/dev/pts	devpts	gid=4,mode=620	0	0
EOF

cat > etc/inittab << EOF
::sysinit:/bin/mount -af

tty1::respawn:/bin/sh

::shutdown:/bin/umount -arf
::ctrlaltdel:/sbin/reboot
EOF

cp -a /etc/mdev.conf etc/

# /usr
mkdir -p usr/share/terminfo/l
cp -a /usr/share/terminfo/l/linux usr/share/terminfo/l

# /tmp
mkdir tmp

# installer
git clone https://github.com/ryojikamei/msi

)
umount $2

gzip -9f $1
mv $1.gz $1
