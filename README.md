# Bodhi Linux 7.0 image fix for Low-RAM computers.

[Bodhi Linux](https://www.bodhilinux.com) 7.0 is a GNU/Linux distribution based on Ubuntu 22.04 LTS. It has a lightweight Moksha Desktop environment and requires only 512 MB RAM for normal operation. This allows it to be used on computers with low RAM.
But the problem is that it takes at least 1024 MB to run the installer and have a live session. You will get a black screen and the message "Kernel panic" if you try to use it on a system with less than 1024 MB of RAM:
```
Failed to execute /init (error -2)
Kernel panic - not syncing: No working init found. (...)
...
---[ end Kernel panic - not syncing: No working init found. ... ]---
```
Here are the instructions and shell scripts for remastering the ISO image of the official distribution so that it can run on 512 MB of RAM. The idea of modification was found in the [article](https://discourse.ubuntu.com/t/reduce-initramfs-size-and-speed-up-the-generation-in-ubuntu-23-10/) _"Reduce initramfs size and speed up the generation in Ubuntu 23.10"_ by Benjamin Drung.

**What you need:**
- GNU/Linux working environment (Bodhi Linux 6.0 is assumed, but not limited to);
- Bodhi Linux 7.0 official distribution [image](https://sourceforge.net/projects/bodhilinux/files/7.0.0/bodhi-7.0.0-64.iso/download);
- shell scripts _repack_initrd.sh_ and _make_iso.sh_ from this repository.

**Note.** The required packages must be installed in your GNU/Linux working environment:
- xz-utilities;
- zstd;
- genisoimage.

Let's start remastering the distribution image!

## I. Preparation.

1) Create a working directory _~/BL70_:
```
$ mkdir ~/BL70
```
2) Place shell scripts _repack_initrd.sh_ and _make_iso.sh_ to the working directory:
```
$ cp repack_initrd.sh make_iso.sh ~/BL70/
```
3) Copy the official distribution ISO image contents to the working directory _~/BL70/isofs_.

_Case A:_ If you have a Bodhi Linux 7.0 DVD- or USB- media, you can attach it to your computer. The filesystem of the media will be mounted in _/media/Bodhi Live CD_. Copy the ISO image contents:
```
$ cp -R '/media/Bodhi Live CD/.' ~/BL70/isofs
```
_Case B:_ If you have a downloaded ISO image file _~/Download/bodhi-7.0.0-64.iso_, you can mount it directly in _/mnt/iso_:
```
$ sudo mkdir /mnt/iso
$ sudo mount -t iso9660 -o ro,loop,uid=$USER,gid=$USER ~/Downloads/bodhi-7.0.0-64.iso /mnt/iso
```
Then copy the ISO image contents:
```
$ cp -R /mnt/iso/. ~/BL70/isofs
```
Unmount the media and delete the mount point directory:
```
$ sudo umount /mnt/iso
$ sudo rmdir /mnt/iso
```
The result of the preparation should look as shown here:
```
-------------------------------------------
~/BL70/
       |- isofs/
       |        |- .disk/
       |        |- boot/
       |        |- casper/
       |        |- ... 
       |- repack_initrd.sh
       |- make_iso.sh
-------------------------------------------
```
## II. Remastering.

1) Go to the working directory:
```
$ cd ~/BL70
```
2) Rebuild the initial RAMFS image _isofs/casper/initrd.gz_ to _isofs/casper/initrd.zst_:
```
$ /bin/sh repack_initrd.sh
```
It may take a few minutes.

3) Replace the old initial RAMFS image with the new one:
```
$ mv isofs/casper/initrd.zst isofs/casper/initrd.gz
```
4) Create a fixed distribution ISO image _~/BL70/bl70_lowram.iso_:
```
$ /bin/sh make_iso.sh
```
5) Move the ISO image _~/BL70/bl70_lowram.iso_ from the working directory to another location to use it for low-RAM computers instead of the official distribution image.

## III. Cleaning the working environment.

Delete the working directory and all it contents to free up space on your disk:
```
$ cd ~
$ rm -fr ~/BL70
```
