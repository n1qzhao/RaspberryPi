# RaspberryPi
Shell scripts for Raspberry Pi
# conf_backup.sh & conf_restore.sh
They can backup and restore (as shown in their names) certain files and/or folders.
At the first run there will be a .conf file in the same path of the script.
It's highly recommanded that put the scripts in your HOME/bin direction.

conf_backup.sh
Useage:
conf_backup.sh [path]
  path: Where to put the backup files. If not given in command line,
        the value specified in SCRITPNAME.conf file will be used.

The files to be backuped should be listed in the SCRIPTNAME.conf file,
bakFiles().
