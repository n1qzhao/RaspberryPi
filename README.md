# RaspberryPi
Shell scripts for Raspberry Pi
# conf_backup.sh & conf_restore.sh
They can backup and restore (as shown in their names) certain files and/or folders.
At the first run there will be a .conf file in the same path of the script.
It's highly recommanded that put the scripts in your HOME/bin direction.

## conf_backup.sh

Usage:
#### conf_backup.sh \[path\]
  path: Where to put the backuped files. If not given in command line,
        the value specified in SCRITPNAME.conf file will be used.

The files to be backuped should be listed in the SCRIPTNAME.conf file,
$bakFiles().

## conf_restore.sh

Usage:
#### conf_restore.sh \[path\]
  path: Where to find the backuped files. If not given in command line,
        the current path will be used.

There is only one variable in the SCRIPTNAME.conf file, $toRoot.
For normal use it should be "/", but other setting for test/special purpose.

# bak2dev.sh, bak2folder.sh & folder2dev.sh
Used for backup the whole raspbian system.
Unlike dd, they just backup(and restore) the useful data, not the entire storage device.
So that you can use a just-fit media.

## bak2dev.sh
Backup boot and / partitions to a device (by default /dev/sda if no input).
All partitions on the target device will be DESTROYED.
The target device can be made bootable, or untouched.

Usage:
#### bak2dev.sh \[dev\]
  dev: To which device the system will be backuped.

## bak2folder.sh
Backup boot and / partitions to a specific folder.
By default /backup if no input by command line.

Usage:
#### bak2folder.sh \[path\]
  path: Where to put the backup.

## folder2dev.sh
Restore a folder-backup to a device.
By default /backup to /dev/sda.

Usage:
#### folder2dev.sh \[path dev\]
  path: The folder holds backup.
  dev: The target device.

## mkDevBootable.sh
It's part of bak2dev.sh, just in case of no making device bootable at the time of backup.

Usage:
#### mkDevBootable.sh \[dev\]
  dev: The target device to be bootable.
