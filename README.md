TOOL:						create_new_VM

VERSION:	      1.1

VERSION DATE:	  20 Sep 15

AUTHOR:	        Brian Philip

README:
This create_new_VM tool is a very simple process to automate the creation and deployment of VMware virtual Linux hosts in my current environment. Its aimed at routine Linux requirements.

The main create_new_VM script is executed from a management host which then uses ssh to the ESXi host to configure and spin up a new VM. The script also grabs the MAC address that VM has assigned and parks that info for later use in the automated delivery cycle. Lastly, the script adds the new host to the chef environment and ensures that its assigned the default role which includes all the standard network services recipes. 

When the VM host starts, Cobbler takes over via PXE to automatically deliver the appropriate kickstart installation which is defined in SpaceWalk/RHN. These components have various dependencies that can not be explained in this readme.

The kickstart profile includes the post-ks-config.bash post script which needs to be run before the RHN registration process. This script uses the MAC address captured earlier to identify the correct host name and make sure the appropriate network config is in place to get the host fully functional and registered in RHN/SpaceWalk. The post install KS script also adds a couple of useful components for management including the chef client. 

STILL TO COME: 
Increase options for sizing VM and choosing OS/release. Add ability to delete and destroy VMs from script. Re-write in Python before bash becomes too unwieldy.

