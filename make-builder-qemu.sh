#!/bin/ash

if [ `whoami` != "root" ]; then
	echo "root privilege is required."
	exit 1
fi

source ~/.nnl-builder/settings
source ~/.msi-creator/conf.qemu

PROG_DIR=$PWD/`dirname $0`
TIMESTAMP=`date +"%Y%m%d%H%M%S"`

##################################################################

#CREATE IMAGE
modprobe nbd max_part=16
#reset
qemu-nbd -v --disconnect $IMG_TGT 2>/dev/null

qemu-img create -f $IMG_TYPE $IMG_DIR/$HOSTNAME-$TIMESTAMP.img $IMG_SIZE
qemu-nbd --connect=$IMG_TGT $IMG_DIR/$HOSTNAME-$TIMESTAMP.img

#FILESYSTEM
sfdisk $IMG_TGT < ~/.msi-creator/qemu-img.layout
mkfs.$FS_TYPE $IMG_ROOT
mkswap $IMG_SWAP

#MOUNT & COPY
MNT=`mktemp -d /tmp/musl.XXXXXXXXXX`
mount $IMG_ROOT $MNT && \
(
cd $OPKG_WORK_TARGET
tar cf - . | ( cd $MNT; tar xvf -)
)

#CONFIGURE
echo "Configure $MNT for single qemu image"
$PROG_DIR/utils/config-tree.sh $MNT

#BUILDER
(
cd $MNT
mkdir -p root/nnl-builder
(
cd $OPKG_WORK_ROOT
tar cf - . | ( cd $MNT/root/nnl-builder; tar xvf -)
)
echo "Removing useless files..."
rm -rf $MNT/root/nnl-builder/build/*
rm -rf $MNT/root/nnl-builder/cross-scripts
rm -rf $MNT/root/nnl-builder/cross-tools
rm -rf $MNT/root/nnl-builder/target-tree
)

#FINALIZE
echo "Unmounting..."
umount $MNT && cat $IMG_MBR > $IMG_TGT && qemu-nbd --disconnect $IMG_TGT
echo "$IMG_DIR/$HOSTNAME-$TIMESTAMP.img is out."

rmdir -v $MNT
