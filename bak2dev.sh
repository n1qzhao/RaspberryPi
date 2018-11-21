#!/bin/bash
# Description:
#  Backup boot and / partitions to a device (by default /dev/sda if no input).
#  All partitions on the target device will be DESTROYED.
#  The target device can be made bootable, or untouched.
# Version:
#  20181024 - First release

function sureRun()
{
  ${1}
  if [ ${?} -eq 0 ]; then
    return 0
  else
    echo "Failure: ${1}"
    exit 3
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
  mntp=/mnt/p
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

bakdev="/dev/sda"

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

if [ -b ${bakdev} ]; then
  read -n 1 -p "All data in ${bakdev} will be deleted! continue/Stop:" arg
  case ${arg} in
    c|C)
      ;;
    *)
      echo -e "\nStopped"
      exit 1
      ;;
  esac
  echo -e  "\nmaking new partitions"
  mkParts ${bakdev} ${devPre}

  echo -e "\nWill backup to \033[32m${bakdev}\033[0m..."
  mnt2F="/mnt/p"
  sudo mkdir -p ${mnt2F}
  sudo mount ${bakdev}${devPre}1 ${mnt2F}
  sudo cp -r /boot/* ${mnt2F}
  sudo touch /mnt/bak$(date +%Y%m%d%H%M%S)
  sudo cp /mnt/bak* ${mnt2F}
  sudo umount ${mnt2F}
  echo -e "\033[32mboot\033[0m partition backuped"

  sudo mount ${bakdev}${devPre}2 ${mnt2F}
  sudo cp /mnt/bak* ${mnt2F}
  sudo rm /mnt/bak*
  cd ${mnt2F}
  sudo mkdir boot
  sudo mkdir dev
  sudo mkdir media
  sudo mkdir mnt
  sudo mkdir proc
  sudo mkdir run
  sudo mkdir sys
  sudo mkdir tmp
  sudo chmod a+w tmp
  sudo rsync --force -rltWDEgopt --stats --progress --exclude '/var/swap' --exclude '.gvfs' --exclude '/dev' --exclude '/media' --exclude '/mnt' --exclude '/proc' --exclude '/run' --exclude '/sys' --exclude '/tmp' --exclude 'lost\+found' --exclude '/boot' // ${mnt2F}
  sudo touch bakend$(date +%Y%m%d%H%M%S)
  echo -e "\033[32m/\033[0m partition backuped"
  cd ~
  sudo umount ${mnt2F}
  sudo rm -r ${mnt2F}
  read -n 1 -p "Backup done. Do you like the backup device bootable?[y/N]:" arg
  case ${arg} in
    y|Y)
      mkDevBootable ${bakdev} ${devPre}
      ;;
    *)
      echo -e "\nLeave the backup untouched"
      ;;
  esac
  exit 0
else
  echo -e "\nDevice not exist"
  exit 2
fi
