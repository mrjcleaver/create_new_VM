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
#################################################################

#################################################################
# DEFINE SOME IMPORTANT VARIABLES FOR THE SCRIPT
ESX_HOST="192.168.1.200"
ESX_USER="root"
ESX_DATASTORE="/vmfs/volumes/datastore1/"
TMP_DIR="/tmp/create_vm"
mkdir -p ${TMP_DIR}
AUTO_BUILD_CONFIG_DIR="/var/www/html/pub/auto_build"
mkdir -p ${AUTO_BUILD_CONFIG_DIR}
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
ssh ${ESX_USER}@${ESX_HOST} "vim-cmd /vmsvc/getallvms" > ${TMP_DIR}/current_vms.tmp
HOST_CHECK=`cat ${TMP_DIR}/current_vms.tmp | grep -v Vmid | awk ' {print $2} ' | sort | grep ${VM_NAME} | wc -l`

if [ ${HOST_CHECK} -gt 0 ]
then
	echo "Sorry. The hostname ${VM_NAME} is already in use. I quit."
	exit
fi

# Add check here to verify OS options (RHEL, CentOS, maybe windows)

# Lets create the new VM
echo "Proceeding to create basic VM host on ${ESX_HOST} called ${VM_NAME} running ${OS}."
ssh ${ESX_USER}@${ESX_HOST} "cd ${ESX_DATASTORE}; mkdir ${VM_NAME}"
ssh ${ESX_USER}@${ESX_HOST} "vmkfstools -c 10G -a lsilogic ${ESX_DATASTORE}/${VM_NAME}/${VM_NAME}.vmdk

