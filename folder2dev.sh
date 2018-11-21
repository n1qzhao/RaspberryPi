#!/bin/bash
# Description:
#  Restore a folder-backup to a device.
#  By default /backup to /dev/sda.
# Version:
#  20181024 - First release

function sureRun()
{
  ${1}
  if [ ${?} -eq 0 ]; then
    return 0
  else
    echo "Failure: ${1}"
    exit 4
  fi
}

function umntDev()
{
  shift
  sudo umount ${*}
  return 0
}

function mkParts()
{
  subDev=`/bin/ls ${1}*`
  umntDev ${subDev}
  sureRun "sudo parted ${1} --script -- mklabel msdos";
  sureRun "sudo parted ${1} --script -- mkpart primary fat32 2048s 206847s"
  sureRun "sudo parted ${1} --script -- mkpart primary ext4 206848s -1s"
  sureRun "sudo mkfs.vfat -F 32 -n boot ${1}${2}1"
  sureRun "sudo mkfs.ext4 -L rootfs ${1}${2}2"
  return 0
}

function mkDevBootable()
{
  partuuid=`sudo fdisk -l ${1} | grep "Disk identifier"`
  partuuid=${partuuid: -8}
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

r2dev="/dev/sda"
bakFolder="/backup"

if [ ${#} -lt 2 ]; then
  read -p "Where is the folder holds backup?[${bakFolder}]:" iFolder
  if [ "${iFolder}" != "" ]; then
    bakFolder=${iFolder}
  fi
  read -p "Which device will be the target?[${r2dev}]:" iDev
  if [ "${iDev}" != "" ]; then
    r2dev=${iDev}
  fi
else
  bakFolder=${1}
  r2dev=${2}
fi

if [ -d ${bakFolder}/boot ] && [ -d ${bakFolder}/rootfs ]; then
  echo "Backup folder confirmed, continue to restore..."
else
  echo "Backup not found! Please check the folder"
  exit 2
fi

if [[ ${r2dev} =~ "mmcblk" ]]; then
  devPre="p"
else
  devPre=""
fi

if [ -b ${r2dev} ]; then
  read -n 1 -p "All data in ${r2dev} will be deleted! continue/Stop:" arg
  case ${arg} in
    c|C)
      ;;
    *)
      echo -e "\nStopped"
      exit 1
      ;;
  esac
  echo -e  "\nmaking new partitions"
  mkParts ${r2dev} ${devPre}

  echo -e "\nWill restore to \033[32m${r2dev}\033[0m..."
  mnt2F="/mnt/p"
  sudo mkdir -p ${mnt2F}
  sudo mount ${r2dev}${devPre}1 ${mnt2F}
  sudo cp -r ${bakFolder}/boot/* ${mnt2F}
  sudo touch /mnt/res$(date +%Y%m%d%H%M%S)
  sudo cp /mnt/res* ${mnt2F}
  sudo umount ${mnt2F}
  echo -e "\033[32mboot\033[0m partition restored"

  sudo mount ${r2dev}${devPre}2 ${mnt2F}
  sudo cp /mnt/res* ${mnt2F}
  sudo rm /mnt/res*
  sudo rsync --force -rltWDEgopt --stats --progress ${bakFolder}/rootfs ${mnt2F}
  sudo touch ${mnt2F}/resend$(date +%Y%m%d%H%M%S)
  echo -e "\033[32m/\033[0m partition restored"
  sudo umount ${mnt2F}
  sudo rm -r ${mnt2F}
  read -n 1 -p "Restore completed. Do you like the new device bootable?[y/N]:" arg
  case ${arg} in
    y|Y)
      mkDevBootable ${r2dev} ${devPre}
      ;;
    *)
      echo -e "\nLeave the new device untouched. Later you can edit /boot/cmdline.txt and /etc/fstab in new device to make it bootable"
      ;;
  esac
  exit 0
else
  echo -e "\nDevice not exist"
  exit 3
fi
