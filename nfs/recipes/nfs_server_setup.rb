#===============================================================================#
# FILE: nfs_setup_client.rb
#===============================================================================#
# PURPOSE: Contains the code for mounting the nfs share
#===============================================================================#
# REQUIRES: nfs-kernel-server package installed
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1.Creates Folders
#   2.Adds to /etc/exports
#   3.Restarts servers
#
#===============================================================================# 
 
 Chef::Log.info "Caylent-Setup: Create export root folder #{node[:opsworks][:nfs][:export_root]}"
  execute "create export root folder" do 
    command "mkdir #{node[:opsworks][:nfs][:export_root]}"
    creates "#{node[:opsworks][:nfs][:export_root]}"
  end
  
  Chef::Log.info "Caylent-Setup: Create export folder #{node[:opsworks][:nfs][:export_full_path]}"
  execute "create export folder" do 
    command "mkdir #{node[:opsworks][:nfs][:export_full_path]}"
    creates "#{node[:opsworks][:nfs][:export_full_path]}"
  end
     
  if (File.exists?("/etc/exports") && File.readlines("/etc/exports").grep(/caylent-nfs-exports/).size < 1) #ToDo improve check and update
    
    Chef::Log.info "Caylent-Setup: No entry found in the /etc/exports adding them now"
    execute 'add export root to exports file' do
      command 'echo "#caylent-nfs-exports" > /etc/exports'
    end
   
    execute 'add export root to exports file' do
      command "echo '#{node[:opsworks][:nfs][:export_root]} 10.0.0.0/8(rw,fsid=0,no_subtree_check,sync)' > /etc/exports" #ToDo Replace fixed subnet masks with dynamic from stack
    end
    
    execute 'add export full path to exports file' do
      command "echo '#{node[:opsworks][:nfs][:export_root]} 10.0.0.0/8(rw,nohide,insecure,no_subtree_check,sync)' > /etc/exports" #ToDo Replace fixed subnet masks with dynamic from stack
    end
    
    execute 'restart nfs kernal' do
      command 'service nfs-kernel-server restart && service idmapd restart'
    end
  end

