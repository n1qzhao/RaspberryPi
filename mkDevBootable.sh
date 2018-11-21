#!/bin/bash
# Description:
#  Make a restored device bootable.
#  It's part of bak2dev.sh, just in case of forget making bootable at once.
# Version:
#  20181024 - First release

bakdev="/dev/sda"

function mkDevBootable()
{
  partuuid=`sudo fdisk -l ${1} | grep "Disk identifier"`
  partuuid="${partuuid: -8}"
  #partuuid="87654321"
  mntp="/mnt/p"
  sudo mkdir -p ${mntp}
  sudo mount ${1}${2}1 ${mntp}
  sudo sed -i "s/\(root=.*rootfs\)/root=PARTUUID=${partuuid}-02 rootfs/" ${mntp}/cmdline.txt
  sudo umount ${mntp}
  sudo mount ${1}${2}2 ${mntp}
  sudo sed -i "s/\(.* \/boot\)/PARTUUID=${partuuid}-01  \/boot/" ${mntp}/etc/fstab
  sudo sed -i "s/\(.* \/ \)/PARTUUID=${partuuid}-02  \/ /" ${mntp}/etc/fstab
  sudo umount ${mntp}
  sudo rm -r ${mntp}
  return 0
}

if [ ${#} -eq 0 ]; then
  read -p "No input, use ${bakdev} as default backup device, or input now:" iDev
  if [ "${iDev}" != "" ]; then
    bakdev=${iDev}
  fi
else
  bakdev=${1}
fi
if [[ ${bakdev} =~ "mmcblk" ]]; then
  devPre="p"
else
  devPre=""
fi
echo -e "\nMake \033[32m${bakdev}\033[0m bootable"
mkDevBootable ${bakdev} ${devPre}
exit 0
