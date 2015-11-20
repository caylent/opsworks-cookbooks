#===============================================================================#
# FILE: nfs_setup_client.rb
#===============================================================================#
# PURPOSE: Contains the code for mounting the nfs share
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1.Check if fstab already modified if not run 2,3 and 4 else add message to logs
#   2.create folder
#   3.Add mount to FSTAB
#   4.mount drives in fstab
#
#===============================================================================# 
 
nfs_layer_primary_server_name = node[:opsworks][:layers]['nfs'][:instances].keys.sort.first
nfs_layer_ip = node[:opsworks][:layers]['nfs'][:instances]["#{nfs_layer_primary_server_name}"][:private_ip]
 
if (File.exists?("/etc/fstab") && File.readlines("/etc/fstab").grep(/caylent/).size < 1) #ToDo improve check and update
 
  #Extra Debuging info
  grep_results_size = File.readlines("/etc/fstab").grep(/caylent/).size
  grep_results = File.readlines("/etc/fstab").grep(/caylent/)
  Chef::Log.info "Caylent-Setup:THe size of the grep query: #{grep_results_size}. It's actual results #{grep_results}"
  
  
  Chef::Log.info "Caylent-Setup: Create folder to mount to"
  execute "create folder to mount" do 
    command "mkdir #{node[:opsworks][:nfs][:mount_folder]}"
  end
  
  Chef::Log.info "caylent-Setup: Adding mount to FSTAB #{nfs_layer_ip}"
  execute "add mount to FSTAB" do
    command "echo '#{nfs_layer_ip}:#{node[:opsworks][:nfs][:export_full_path]} #{node[:opsworks][:nfs][:mount_folder]} nfs auto 0 0' >> /etc/fstab" 
  end
   
  Chef::Log.info "caylent-Setup:mount newly added drives"
  execute "mount drives" do 
    command "mount -a"
  end
else
 
  Chef::Log.info "caylent-Setup:skipped Mount add as fstab already contains entry or doesn't exist"
 
end

