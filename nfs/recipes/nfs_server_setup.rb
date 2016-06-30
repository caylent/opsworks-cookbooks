#===============================================================================#
# FILE: nfs_setup_client.rb
#===============================================================================#
# PURPOSE: Contains the code for mounting the nfs share
#===============================================================================#
# REQUIRES: nfs-kernel-server package installed
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1.Installes Package
#   2.Creates Folders
#   2.Adds to /etc/exports
#   3.Restarts servers
#
#===============================================================================# 
 
    package 'Install nfs-kernel-server' do 
        case node[:platform]
        when 'ubuntu', 'debian' #ToDo extend to other platforms
          package_name 'nfs-kernel-server'
        end
        notifies :run, 'execute[folder setup]', :immediately
    end

    Chef::Log.info "Caylent-Setup: Create export root folder #{node[:opsworks][:nfs][:export_root]}"
    execute "folder setup" do 
        command "mkdir #{node[:opsworks][:nfs][:export_root]} && mkdir #{node[:opsworks][:nfs][:export_full_path]}"
        creates "#{node[:opsworks][:nfs][:export_root]}"
        action :nothing
        notifies :run, 'execute[add details to /etc/exports]', :immediately
    end
            
   #Chef::Log.info "Caylent-Setup:THe size of the grep query: #{grep_results_size}. It's actual results #{grep_results}"

       
    Chef::Log.info "Caylent-Setup: No entry found in the /etc/exports adding them now"
    execute 'add details to /etc/exports' do
        command "echo -e '# Caylent Nfs Exports caylent-nfs-exports\n' >> /etc/exports && echo -e '#{node[:opsworks][:nfs][:export_root]} #{node[:opsworks][:nfs][:network_cidr]}(rw,fsid=0,no_subtree_check,sync)\n' >> /etc/exports && echo '#{node[:opsworks][:nfs][:export_full_path]} #{node[:opsworks][:nfs][:network_cidr]}(rw,nohide,insecure,no_subtree_check,sync)' >> /etc/exports"
        not_if {File.readlines("/etc/exports").grep(/caylent-nfs-exports/).size == 1}
        action :nothing
    end

