#!/bin/bash
# ******************************************
# Terumo TR01&12 BI 12hr + OS clone script
# Created by Chin Ming Lee
# ******************************************

failRedDialog(){
	echo Test End : $(date) >> $logFile
	echo "****** TEST_FAILED! ****** " >> $logFile
	dialog --title  TESTING_RESULT  --colors --yesno\
	"\Zb\Z1----------------------------------\
	FFFFFF______A______IIIIII___LL____\
	FF________AA_AA______II_____LL____\
	FF_______AA___AA_____II_____LL____\
	FFFF_____AA___AA_____II_____LL____\
	FF_______AA___AA_____II_____LL____\
	FF_______AA_A_AA_____II_____LL____\
	FF_______AA___AA___IIIIII___LLLLLL\
	----------------------------------\Zn\n 
	$1 \n\
	Yes= Test again\n No= Power off 
	" 20 55
	#0=yes 1=no 255=Esc
	response=$?
	case $response in
		0)
		   clear
		   sudo /run/live/medium/my-clonezilla
		   exit
		exit 0 ;;
		1) 
		   sync
		   sudo shutdown -h now
		exit 1 ;;	
		255) 
		   #echo "cd $SCR_LOC; sudo bash run_main.sh" > $SCR_LOC/t.sh
                   #sudo bash $SCR_LOC/t.sh
		exit 255 ;;
	esac
}

logFileCheck(){
	#Check logfile folder 
	logFolder="/home/partimag/log"
	[ ! -d $logFolder ] && mkdir -p $logFolder
	dmiGetSn="$(sudo dmidecode -s system-serial-number)"
	logFile=$logFolder/$dmiGetSn.log
	echo " " >> $logFile
	echo "****** Contact chinminglee@onyx-healthcare.com for script issues ****** " >> $logFile
	echo "****** TEST_START! ****** " >> $logFile
}

pnCheck(){
	pn=$(sudo dmidecode -s system-product-name)
	echo "- Check Dmi Product Name : $pn" | tee -a $logFile
}

biosDateCheck(){
	biosDate=$(sudo dmidecode -s bios-release-date)
	echo "- Check Dmi BIOS Release Date : $biosDate" | tee -a $logFile
}

snLenCheck(){
	dmiGetSnLen="$(sudo dmidecode -s system-serial-number | wc -m)"
	dmiGetSnLen=$(($dmiGetSnLen - 1))
	if [ $dmiGetSnLen == 8 ] || [ $dmiGetSnLen == 9 ] ; then
		echo "- Check Serial Number $dmiGetSn length $dmiGetSnLen passed!" | tee -a $logFile
	else
		echo "****** Check serial number $dmiGetSn length $dmiGetSnLen failed! ******" | tee -a $logFile
		failRedDialog "Check serial number $dmiGetSn length $dmiGetSnLen failed!"
	fi
}

biTimeSet(){
	#get time stamp
	timeStart=$((`date +%s`))
	timeStartDate=$(date --date=@$timeStart)
	#set end time for 12hr(43200sec)
	timeEnd=$((`date +%s` + 43201))
	#timeEnd=$((`date +%s` + 3600))
	timeEndDate=$(date --date=@$timeEnd)
	timeNow=$((`date +%s`))
	#timeShow=$(date '+%Y/%m/%d-%H:%M:%S')
	echo - Test Time Str : $timeStartDate >> $logFile
	echo - Test Time End : $timeEndDate >> $logFile
}

memTesterRun(){
	#a是否大於等於b
	COUNT=1
	while [ $timeEnd -ge $timeNow ]; do
		echo Test Str : $timeStartDate
		echo Test End : $timeEndDate
		echo Test Now : $(date)
		#memtester run 100m about 1min, 400m x 8 cycle about 30min pre-run
		memtester 400m 8
		if [ $? = 0 ]; then
			echo "- Check memtester run $COUNT passed !" | tee -a $logFile
		else
			echo "****** Check memtester run $COUNT failed !  ******" | tee -a $logFile 
			failRedDialog "Check memtester run $COUNT failed !"
		fi
		sleep 5
		COUNT=$(($COUNT+1))
		timeNow=$((`date +%s`))
		clear
	done
	echo - memTester End : $(date) >> $logFile	
}



#-g auto -e1 auto -e2 -r -j2 -k0 -scr -p reboot restoredisk 2024-06-26-19-img-md101 mmcblk0
cloneRun(){
	cloneOs="2024-06-26-19-img-md101"
	#cloneDisk="mmcblk0"
	cloneDisk=$(lsblk -o NAME,MODEL | grep mmcblk | awk 'NR == 1')
	#cloneOs='2024-07-03-06-img-mate2-2x12-win11-32g'
	#cloneDisk='sda'
	echo "- clone OS : $cloneOs " >> $logFile
	echo "- clone Disk : $cloneDisk " >> $logFile
	#-g, --grub-install GRUB_PARTITION Install grub in the MBR of the disk
	#-e1, --change-geometry NTFS-BOOT-PARTITION Force to change the CHS (cylinders, heads, sectors) value of NTFS boot partition after image is restored.
	#-e2, --load-geometry-from-edd Force to use the CHS (cylinders, heads, sectors) from EDD (Enhanced Disk Device) when creating partition table by sfdisk
	#-r, --resize-partition Resize the partition when restoration finishes, this will resize the file system size to fit the partition size.
	#-j2, --clone-hidden-data Use dd to clone the image of the data between MBR (1st sector, i.e. 512 bytes) and 1st partition, which might be useful for some recovery tool.
	#-k0, Create partition table based on the partition table from the image. this is the same as as default. Just an option to let us explain the action easier.
	#-k1, Create partition table in the target disk proportionally.
	#-scr, --skip-check-restorable-r By default Clonezilla will check the image if restorable before restoring. This option allows you to skip that.
	#-icds, --ignore-chk-dsk-size-pt Skip checking destination disk size before creating the partition table on it.
	#-p, --postaction [choose|poweroff|reboot|command|CMD] When save/restoration finishes, choose action in the client, poweroff, reboot (default), in command prompt or run CMD
	#-batch : 批次處理模式。不會向使用者確認任何事項
	
	sudo /usr/sbin/ocs-sr -batch -g auto -e1 auto -e2 -r -j2 -k0 -scr -p reboot restoredisk $cloneOs $cloneDisk
	#sudo /usr/sbin/ocs-sr -g auto -e1 auto -e2 -r -j2 -k1 -scr -icds -p choose restoredisk 2024-07-03-06-img-mate2-2x12-win11-32g sda
	cloneCheck=$?
	if [ $cloneCheck = 0 ]; then
		echo "- Check clonezilla restore passed !" | tee -a $logFile
		echo "****** TEST_DONE! ****** " >> $logFile
		mv $logFolder/$dmiGetSn.log $logFolder/$dmiGetSn-PASS.log
		sleep 5
		sync
		sudo shutdown -h now
	else
		echo "****** Check clonezilla failed !  ******" | tee -a $logFile 
		failRedDialog "Check clonezilla check $cloneCheck failed !"
	fi
	#開始燒CPU
	#for i in `seq 1 $(cat /proc/cpuinfo | grep "physical id" | wc -l)`; do dd if=/dev/zero of=/dev/null & done
	#結束燒CPU
	#pkill dd
}

logFileCheck
pnCheck
biosDateCheck
#snLenCheck
#biTimeSet
#memTesterRun
cloneRun
