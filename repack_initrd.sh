#!/bin/sh
###
# This script is designed to minimize the size of initial RAM filesystem
# (initramfs) of the Bodhi Linux 7.0 distribution.
# Created by Ihar Areshchankau <robursw@gmail.com>, March 2024.
# License: CC BY 4.0 (http://creativecommons.org/licenses/by/4.0/)
#
# Before using this script:
# - copy the distribution image contents into the directory ./isofs:
#     mkdir ./isofs
#     cp -R /mnt/iso/. ./isofs
#   where /mnt/iso is the mount point of the original distribution image.
# - be sure that the hidden directory .disk was copied:
#     ls -l ./isofs/.disk
###
LANG=POSIX
SRC_INITRD=./isofs/casper/initrd.gz
TGT_INITRD=./isofs/casper/initrd.zst
INITRAMFS=./initramfs
SGN_CPIO="ASCII cpio archive"
SGN_ZSTD="Zstandard compressed data"
OFFSET=0
[ -f $SRC_INITRD ] || { echo "ERROR: Source file not found: $SRC_INITRD"; exit 1; }

echo "Search for the compressed initramfs in $SRC_INITRD."
CONTENT="`dd if=$SRC_INITRD bs=512 skip=$OFFSET | file -`"
while echo "$CONTENT" | grep -q "$SGN_CPIO"
do
echo "Skip part at: $OFFSET"
SIZE=`dd if=$SRC_INITRD bs=512 skip=$OFFSET | cpio -it 2>&1 | grep block | cut -d ' ' -f 1`
OFFSET=$(($OFFSET+$SIZE))
CONTENT="`dd if=$SRC_INITRD bs=512 skip=$OFFSET | file -`"
done

if echo "$CONTENT" | grep -q "$SGN_ZSTD"
then
echo "Compressed initramfs found at: $OFFSET"
else
echo 'Compressed initramfs not found.'
exit 1
fi

echo "Extract initramfs content into $INITRAMFS."
[ -d $INITRAMFS ] && rm -fr $INITRAMFS
mkdir $INITRAMFS
dd if=$SRC_INITRD bs=512 skip=$OFFSET | unzstd | cpio -idD $INITRAMFS

echo 'Compress kernel modules.'
# find $INITRAMFS/usr/lib/modules/*/kernel -name *.ko \
# 	-exec zstd --compress -19 -o '{}.zst' '{}' \; -and\
# 	-exec rm '{}' \;

find $INITRAMFS/usr/lib/modules/*/kernel -name *.ko \
	-exec zstd --compress -19 -o '{}.zst' '{}' \; -and\
	-exec mv '{}.zst' '{}' \;

# echo 'Update modules dependencies.'
# depmod -ab $INITRAMFS
echo 'Compress firmware.'
find $INITRAMFS/usr/lib/firmware -type f \
	-exec echo '{}' \; \
	-and -exec xz --compress -C crc32 '{}' \;

echo "Pack everything into $TGT_INITRD"
{
dd if=$SRC_INITRD bs=512 count=$OFFSET
cd $INITRAMFS
(echo '.'; echo './usr'; echo './usr/lib'; echo './usr/lib/modules'; \
ls -1d ./usr/lib/modules/*; \
find ./usr/lib/modules/*/kernel ./usr/lib/firmware) | cpio -H newc -o
rm -fr ./usr/lib/modules/*/kernel ./usr/lib/firmware
find . | cpio -H newc -o | zstd -8
cd ..
} > $TGT_INITRD

rm -fr $INITRAMFS
echo 'Done.'
