#!/bin/bash

# wget https://github.com/mingzhangqun/reCamera_ota/raw/master/upgrade.json
# parse() upgrade.json
upgrade_fip=1
upgrade_boot=1
upgrade_fs=1

PATH_BOOT="/var/boot"
PATH_DATA="/var/data"

mkdir ${PATH_BOOT}
mkdir ${PATH_DATA}

mount /dev/mmcblk0p1 ${PATH_BOOT}
mount /dev/mmcblk0p4 ${PATH_DATA}

mkdir -p /var/data/upgrade
cd /var/data/upgrade

# wget https://github.com/mingzhangqun/reCamera_ota/raw/master/fip.bin
# wget https://github.com/mingzhangqun/reCamera_ota/raw/master/boot.sd
# wget https://github.com/mingzhangqun/reCamera_ota/raw/master/rootfs_ext4.sd.xz

mv -f ${PATH_BOOT}/fip.bin ${PATH_BOOT}/fip.bin.bak
mv -f ${PATH_BOOT}/boot.sd ${PATH_BOOT}/boot.sd.bak

cp fip.bin ${PATH_BOOT}/
cp boot.sd ${PATH_BOOT}/

xz -d rootfs_ext4.sd.xz

if [ -e "rootfs_b" ]; then
dd if=rootfs_ext4.sd of=/dev/mmcblk0p2
# checksum()
rm rootfs_b
else
dd if=rootfs_ext4.sd of=/dev/mmcblk0p3
# checksum()
touch ${PATH_BOOT}/rootfs_b
fi

sync
cd /

umount ${PATH_BOOT}
umount ${PATH_DATA}