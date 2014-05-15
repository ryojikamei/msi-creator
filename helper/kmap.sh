#!/bin/ash

# Generate a binary keymap archive from keymaps

cd /usr/share/keymaps/i386
MAPS=`find ./ -name "*.map.gz" | cut -f 2- -d'/' | grep -v ^include`
TMP=/tmp
KMAPS=kmaps
ARCHIVE=$TMP/kmaps.tar.gz

# current
dumpkeys > /tmp/current.map

rm -rf ${TMP}/${KMAPS}
mkdir -pv ${TMP}/${KMAPS}

for k in $MAPS; do
	dir=`dirname $k`
	name=`basename $k .map.gz`
	loadkeys -q -b $k > ${TMP}/${KMAPS}/${name}@${dir}
done
cd ${TMP}/${KMAPS}
tar -zcf $ARCHIVE *

loadkeys /tmp/current.map
rm -f /tmp/current.map
rm -rf ${TMP}/${KMAPS}
