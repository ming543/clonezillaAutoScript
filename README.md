# clonezilla
clonezilla automatic run script

Update BOOT/GRUB.CFG
- USB disk name set to  'MD101'
- clonezilla recovery folder at root directory 
  (setup grub.cfg ocs_repository="dev:///LABEL=MD101")

- add my-clonezilla-os.sh at root
  (setup grub.cfg ocs_live_run="sudo /run/live/medium/my-clonezilla-os")
