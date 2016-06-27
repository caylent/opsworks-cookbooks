############################################################
# Default Attributes file for NFS Cookbook
############################################################
# Includes the attributes for NFS recipes
############################################################



############################################################
# NFs Setup Attributes
############################################################

#client
default[:opsworks][:nfs][:mount_folder] = "/mnt/caylent-nfs"
#server
default[:opsworks][:nfs][:export_root] = "/export"
default[:opsworks][:nfs][:export_folder] = "/caylent-nfs"
default[:opsworks][:nfs][:export_full_path] = "#{node[:opsworks][:nfs][:export_root]}#{node[:opsworks][:nfs][:export_folder]}"


#Generic shared path variable made avaiable by any caylent File Share tiers
#default[:opsworks][:fs_tier][:export_full_path] = node[:opsworks][:shared][:export_full_path]
############################################################
# nfs Deployment Attributes
############################################################


