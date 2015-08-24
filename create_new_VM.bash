#!/bin/bash
#################################################################
# SCRIPT:	create_new_VM  
# VERSION:	1.0
# VERSION DATE:	24 Aug 15
# AUTHOR:	Brian Philip
# DESCRIPTION:	Basic bash script to automate the creation of
#		VM machines and then pop the VM MAC address
#		into a convenient location for us to use later 
#		in the automated build process.
#
#		Current version is limited to only RHEL7 and
#		is hard coded VM sizing. To be expanded when 
#		time permits.
#		
#		The purpose of the auto build area is just to
#		dump the MAC address of the host for use else
#		where in the automation cycle. 
#################################################################

#################################################################
# DEFINE SOME IMPORTANT VARIABLES FOR THE SCRIPT
ESX_HOST="192.168.1.200"
ESX_USER="root"
ESX_DATASTORE="/vmfs/volumes/datastore1/"
TMP_DIR="/tmp/create_vm"
AUTO_BUILD_CONFIG_DIR="/var/www/html/pub/auto_build"
mkdir -p ${TMP_DIR}
mkdir -p ${AUTO_BUILD_CONFIG_DIR}
TODAY=`date +%x`
#################################################################

while [[ $# > 1 ]]
do
	key="$1"
	case $key in
		-n)
    			VM_NAME=`echo $2 | tr '[a-z]' '[A-Z]'`
    			shift 
    		;;
    		-o)
    			OS="$2"
    			shift 
    		;;
		# Add extra switch options to allow more dynamic sizing of CPU, RAM, disk, or maybe predefined profiles
    		*)
            		echo "Sorry. Unknown option provided. I quit"
			exit
    		;;
	esac
	shift
done

# Lets start by checking if the host already exists on ESX
ssh ${ESX_USER}@${ESX_HOST} "vim-cmd /vmsvc/getallvms" > ${TMP_DIR}/${VM_NAME}_current_vms.tmp
HOST_CHECK=`cat ${TMP_DIR}/${VM_NAME}_current_vms.tmp | grep -v Vmid | awk ' {print $2} ' | sort | grep ${VM_NAME} | wc -l`
DATASTORE_CHECK=`ssh ${ESX_USER}@${ESX_HOST} "if [ -d '${ESX_DATASTORE}/${VM_NAME}' ];then echo 'EXISTS';fi"`

if [ ${HOST_CHECK} -gt 0 ]
then
	echo "Sorry. The hostname ${VM_NAME} is already in use. I quit."
	exit
fi

if [ "${DATASTORE_CHECK}" == "EXISTS" ]
then
        echo "Sorry. The hostname ${VM_NAME} is already in the data store. I quit."
        exit
fi

# Add future check here to verify OS options (RHEL, CentOS, maybe windows)

# Lets create the new VM
echo "Proceeding to create basic VM host on ${ESX_HOST} called ${VM_NAME} for ${OS}."
ssh ${ESX_USER}@${ESX_HOST} "cd ${ESX_DATASTORE}; mkdir ${VM_NAME}" > /dev/null 2>&1
ssh ${ESX_USER}@${ESX_HOST} "vmkfstools -c 10G ${ESX_DATASTORE}/${VM_NAME}/${VM_NAME}.vmdk" > /dev/null 2>&1

cat << EOF > $TMP_DIR/${VM_NAME}.vmx.tmp

.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "11"
nvram = "${VM_NAME}.nvram"
pciBridge0.present = "TRUE"
svga.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"
vmci0.present = "TRUE"
hpet0.present = "TRUE"
memSize = "2048"
numvcpus = "2"
sched.cpu.units = "mhz"
powerType.powerOff = "soft"
powerType.suspend = "hard"
powerType.reset = "soft"
ide1:0.deviceType = "cdrom-image"
ide1:0.present = "TRUE"
floppy0.startConnected = "FALSE"
floppy0.clientDevice = "TRUE"
floppy0.fileName = "vmware-null-remote-floppy"
ethernet0.virtualDev = "e1000"
ethernet0.networkName = "VM Network 2"
ethernet0.addressType = "generated"
ethernet0.present = "TRUE"
displayName = "${VM_NAME}"
guestOS = "centos-64"
toolScripts.afterPowerOn = "TRUE"
toolScripts.afterResume = "TRUE"
toolScripts.beforeSuspend = "TRUE"
toolScripts.beforePowerOff = "TRUE"
chipset.onlineStandby = "FALSE"
sched.cpu.min = "0"
sched.cpu.shares = "normal"
sched.mem.min = "0"
sched.mem.minSize = "0"
sched.mem.shares = "normal"
virtualHW.productCompatibility = "hosted"
replay.supported = "FALSE"
replay.filename = ""
migrate.hostlog = "./${VM_NAME}.hlog"
pciBridge0.pciSlotNumber = "17"
pciBridge4.pciSlotNumber = "21"
pciBridge5.pciSlotNumber = "22"
pciBridge6.pciSlotNumber = "23"
pciBridge7.pciSlotNumber = "24"
ethernet0.pciSlotNumber = "32"
vmci0.pciSlotNumber = "33"
ethernet0.generatedAddressOffset = "0"
monitor.phys_bits_used = "42"
vmotion.checkpointFBSize = "4194304"
vmotion.checkpointSVGAPrimarySize = "4194304"
cleanShutdown = "FALSE"
softPowerOff = "FALSE"
tools.remindInstall = "TRUE"
scsi0.virtualDev = "lsilogic"
scsi0.present = "TRUE"
scsi0:0.deviceType = "scsi-hardDisk"
scsi0:0.fileName = "${VM_NAME}.vmdk"
scsi0:0.present = "TRUE"
scsi0:0.redo = ""
scsi0.pciSlotNumber = "16"
EOF

scp $TMP_DIR/${VM_NAME}.vmx.tmp ${ESX_USER}@${ESX_HOST}:${ESX_DATASTORE}/${VM_NAME}/${VM_NAME}.vmx > /dev/null 2>&1

# Thats the basics in place so lets register the VM
ssh ${ESX_USER}@${ESX_HOST} "vim-cmd solo/registervm ${ESX_DATASTORE}/${VM_NAME}/${VM_NAME}.vmx" > ${TMP_DIR}/${VM_NAME}.vmx.reg
VM_ID=`cat ${TMP_DIR}/${VM_NAME}.vmx.reg`

# We want to perform a quick check to see if the registration worked. If we have an integer ID it almost certainly did. If not then we undo and quit.
CHECK_PATTERN='^[0-9]+$'
if ! [[ ${VM_ID} =~ ${CHECK_PATTERN} ]]
then
	echo "I appear to have had an issue registering this VM host. I will now undo the creation and quit.  Here is the registration error:"
	ssh ${ESX_USER}@${ESX_HOST} "rm -rf ${ESX_DATASTORE}/${VM_NAME}"
	cat ${TMP_DIR}/${VM_NAME}.vmx.reg
	exit
else
	echo "Host successfully registered. Now powering on VM ID ${VM_ID}."
	ssh ${ESX_USER}@${ESX_HOST} "vim-cmd vmsvc/power.on $VM_ID" > /dev/null 2>&1
	
	# Lets perform a quick check to verify the host is up
	sleep 20
	ssh ${ESX_USER}@${ESX_HOST} "vim-cmd vmsvc/power.getstate 10 | tail -1" > ${TMP_DIR}/${VM_NAME}.power
	IS_ON=`cat ${TMP_DIR}/${VM_NAME}.power | grep "Powered on" | wc -l`

	if [ ${IS_ON} -gt 0 ]
	then
		echo "${VM_NAME} has been successfully created and is powered on."
	else
		echo "${VM_NAME} could not be powered on. Investigate from vSphere client."
	fi

	# Grab the MAC address VM has provided to the host and drop it in the auto build area for future ref
	MAC_ADD=`ssh ${ESX_USER}@${ESX_HOST} "cat ${ESX_DATASTORE}/${VM_NAME}/${VM_NAME}.vmx | grep generatedAddress | grep -v Offset" | sed 's/ethernet0.generatedAddress = "//g' | sed 's/"//g'`
	echo "${TODAY},${VM_NAME},${MAC_ADD}" > ${AUTO_BUILD_CONFIG_DIR}/${VM_NAME}.auto.csv
fi

# Clean up logs
rm -rf ${TMP_DIR}/${VM_NAME}*
