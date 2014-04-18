#!/bin/ash

if [ "x`uname -a | grep musl`" == "x" ]; then
	echo "It must be run on native musl system."
	exit 1
fi

source ~/.nnl-builder/settings

PKGS="\
musl_1.0.1-1_i486.opk \
busybox_1.22.1-3_i486.opk \
linux_3.2.57-1_i486.opk \
syslinux_4.07-1_i486.opk \
"

#WORK_DIR=`mktemp -d $OPKG_WORK_BUILD/geniso.XXXXXXXXXX`
WORK_DIR=$OPKG_WORK_BUILD/geniso.1
rm -rf $WORK_DIR && mkdir -p $WORK_DIR

cd $WORK_DIR
mkdir -p ext iso

for p in $PKGS; do
	ar x $OPKG_WORK_PKGS/$p data.tar.gz
	tar xvf data.tar.gz -C ext
	rm -f data.tar.gz
done

cd ../iso
mkdir -v bin boot dev tmp
# BOOT
cp -a ../ext/usr/share/syslinux/isolinux.bin boot/
cp -a ../ext/boot/vmlinuz* boot/
# BIN
cp -a ../ext/bin/* bin/

# ISOLINUX.CFG
cat > boot/isolinux.cfg <<EOF
default linux
label linux
kernel vmlinuz
append ro init=/bin/busybox
EOF

#rm -rf $WORK_DIR
