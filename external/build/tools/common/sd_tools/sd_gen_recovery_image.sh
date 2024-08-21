#!/bin/bash
# a sd image generator for sophpi
# usage
if [ "$#" -ne "2" ]
then
	echo "usage: sudo ./sd_gen_burn_image.sh OUTPUT_DIR IMAGE_NAME"
	echo ""
	echo "       The script is used to create a sdcard image with two partitions, "
	echo "       one is fat32 with 128MB, the other is ext4 with 256MB."
	echo "       You can modify the capacities in this script as you wish!"
	echo ""
	echo "Note:  Please backup you sdcard files before using this image!"

	exit
fi

function size2sectors() {
    local f=0
    for v in "${@}"
    do
    local p=$(echo "$v" | awk \
      'BEGIN{IGNORECASE = 1}
       function printsectors(n,b,p) {printf "%u\n", n*b^p/512}
       /B$/{     printsectors($1,  1, 0)};
       /K(iB)?$/{printsectors($1,  2, 10)};
       /M(iB)?$/{printsectors($1,  2, 20)};
       /G(iB)?$/{printsectors($1,  2, 30)};
       /T(iB)?$/{printsectors($1,  2, 40)};
       /KB$/{    printsectors($1, 10,  3)};
       /MB$/{    printsectors($1, 10,  6)};
       /GB$/{    printsectors($1, 10,  9)};
       /TB$/{    printsectors($1, 10, 12)}')
    for s in $p
    do
        f=$((f+s))
    done

    done
    echo $f
}

part_label="RECOVERY"
part_cap=1024M
part_start=2048
part_size=$(size2sectors ${part_cap})

function create_disk_mbr() {
    echo "Run ${FUNCNAME[0]}"
    if [ -z "${1}" ]; then
        echo "image name is empty"
        exit 1
    fi

    image=$1
    dd if=/dev/zero of=./${image} bs=512 count=${part_size}

    # Create the disk image
    (
        echo "label: dos"
        echo "label-id: 0x48617373"
        echo "unit: sectors"
        echo "boot  : start= ${part_start},     size= ${part_size},     type=c, bootable"   #create the boot partition
    ) | sfdisk ${image} 
    #> sfdisk --force -uS ${image}

    echo "${FUNCNAME[0]} ok"
}

function write_boot_part() {
    echo "Run ${FUNCNAME[0]}"
    if [ -z $1 ]; then
        echo "image name is empty"
        exit 1
    fi

    local part=$(mktemp)

    dd if=/dev/zero of=${part} bs=512 count=${part_size}
    mkfs.vfat -n ${part_label} ${part}

    mcopy -i ${part} fip.bin ::
    mcopy -i ${part} boot.emmc ::
    mcopy -i ${part} rootfs_ext4.emmc ::

    dd if=${part} of=${1} seek=${part_start} bs=512 conv=notrunc,sparse

    rm -rf ${part}
    echo "${FUNCNAME[0]} ok"
}

# Start gen image
pushd $1 || exit 1
# target=$2_`date +%Y%m%d%H%M`
target=$2
image_name=${target}.img
echo "Image: ${image_name}"
rm -rf ${target}*
create_disk_mbr $image_name || exit 1
write_boot_part $image_name || exit 1

zip -j ${target}.zip ${image_name}
rm -rf ${image_name}
popd
