#!/bin/bash

# milkv sd image generator

# usage
if [ "$#" -ne "1" ]; then
  echo "usage: ${0} OUTPUT_DIR"
  echo ""
  echo "       The script is used to create a sdcard image with two partitions, "
  echo "       one is fat32 with 128MB, the other is ext4 with 256MB."
  echo "       You can modify the capacities in genimage cfg as you wish!"
  echo "       genimage cfg: genimage.cfg"
  echo ""
  echo "Note:  Please backup you sdcard files before using this image!"

  exit
fi

echo "BR_DIR: $BR_DIR"
echo "BR_BOARD: $BR_BOARD"

# 获取脚本的完整路径  
script_full_path=$(readlink -f "$0")  

# 获取脚本所在的目录  
script_dir=$(dirname "$script_full_path")  

export PATH=${script_dir}:${PATH}

output_dir=$1
echo ${output_dir}
pushd ${output_dir}

[ -d tmp ] && rm -rf tmp

genimage --config ${script_dir}/genimage.cfg --rootpath rootfs/ --inputpath ${PWD} --outputpath ${PWD}
if [ $? -eq 0 ]; then
    echo "gnimage for sophpi-seeed success!"
else
    echo "gnimage for sophpi-seeed failed!"
fi

popd
