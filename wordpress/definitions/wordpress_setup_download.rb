#===============================================================================#
# FILE: download_wordpress.rb
#===============================================================================#
# PURPOSE: Download a shared version of wordpress 
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1. Check check for tar file if not execute 2,3 and 4
#   2 and 3. download and extract correct version
#   4. remove unwanted wp-content (thisi is replaced by git repo for app later)
#===============================================================================# 


define wordpress_setup_download do

  if !File.exists?("/tmp/wordpress-#{node[:opsworks][:wordpress][:version]}.tar.gz")
      
    Chef::Log.info "Caylent-setup: Downloading wordpress version #{node[:opsworks][:wordpress][:version]}"
    execute "download wordpress" do
      command "wget https://wordpress.org/wordpress-#{node[:opsworks][:wordpress][:version]}.tar.gz"
      cwd "/tmp"
    end
    Chef::Log.info "Caylent-setup: Extracting wordpress"
    execute "extract tar" do
      command "tar -xvzf wordpress-#{node[:opsworks][:wordpress][:version]}.tar.gz"
      cwd "/tmp"
    end
    Chef::Log.info "Caylent--setup: Removing word wordpress/wp-content folder"
    execute "remove wp-content" do
      command "rm -R wordpress/wp-content"
      cwd "/tmp"
    end
  end
end
