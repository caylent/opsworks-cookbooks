#Description

Opsworks Client and Server NFS Config for Ubuntu/Debian

#Configuration

##Server
Create "nfs" layer
Add "nfs::nfs_server_setup" to layer serup recipes

##Client
*Can be added to any layer requiring nfs access*

**Setup will file if no nfs layer has "running" status**  
Add "nfs-common" to OS Packages.
Add "nfs::nfs_server_setup" to layer serup recipes.

#Note
The nfs layer will require 2 runs of setup to make nfs available of the network.

