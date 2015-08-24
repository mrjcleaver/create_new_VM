#################################################################
# TOOL:           create_new_VM  
# VERSION:	      1.0
# VERSION DATE:	  24 Aug 15
# AUTHOR:	        Brian Philip

README:
This create_new_VM tool is a very simple process to automate the creation and deployment of VMware virtual Linux hosts in my current environment. Currently its targetted at basic Linux requirements.

The main create_new_VM script is executed from a management host which then uses ssh to the ESXi host to configure and spin up a new VM. The script also grabs the MAC address that VM has assigned and parks that info for later use in the automated delivery cycle.

From here Cobbler takes over via PXE to automatically deliver the appropriate kickstart installation which is defined in SpaceWalk/RHN. These components have various dependencies that can not be explained in this readme.

The kickstart profile includes the post-ks-config.bash post script which needs to be run before the RHN registration process. This script uses the MAC address captured earlier to identify the correct host name and make sure the appropriate network config is in place to get the host fully functional and registered in RHN/SpaceWalk.

STILL TO COME: 
Increase options for sizing VM and choosing OS/release
Post script to install / config Chef client
Let Chef do its thing
