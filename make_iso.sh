#!/bin/sh
###
# This script is designed for building modified distribution ISO image 
# based on the filesystem contents.
# Created by Ihar Areshchankau <robursw@gmail.com>, February 2024.
# License: CC BY 4.0 (http://creativecommons.org/licenses/by/4.0/)
###

ISO_FS=./isofs
ISO_LABEL=BL70_LOWRAM
ISO_FILE=./bl70_lowram.iso

[ -d $ISO_FS ] || { echo "ERROR: Directory of the image contents not found - $ISO_FS"; exit 1; }

echo 'Checksums calculation. Please wait.'
cd $ISO_FS
md5sum `find ./ -type f | \
grep -v -e "\./md5sum\.txt" -e "\./isolinux/"` > ./md5sum.txt
cd ..

echo 'ISO image generation. Please wait.'
[ -f $ISO_FILE ] && rm $ISO_FILE
genisoimage -lrJV "$ISO_LABEL" \
-input-charset default \
-c isolinux/boot.cat -b isolinux/isolinux.bin \
-no-emul-boot -boot-load-size 4 -boot-info-table \
-eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
-o $ISO_FILE $ISO_FS
isohybrid -u $ISO_FILE

echo "ISO image $ISO_FILE ready."
echo 'Done.'
