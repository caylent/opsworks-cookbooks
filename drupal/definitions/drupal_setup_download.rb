#===============================================================================#
# FILE: download_drupal.rb
#===============================================================================#
# PURPOSE: Download a shared version of drupal 
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1. Check check for tar file if not execute 2,3 and 4
#   2 and 3. download and extract correct version
#   4. remove unwanted drupal-content (thisi is replaced by git repo for app later)
#===============================================================================# 


define drupal_setup_download do

  if !File.exists?("/tmp/drupal-#{node[:opsworks][:drupal][:version]}.tar.gz")
      
    Chef::Log.info "Caylent-setup: Downloading drupal version #{node[:opsworks][:drupal][:version]}"
    execute "download drupal" do
      command "wget https://drupal.org/drupal-#{node[:opsworks][:drupal][:version]}.tar.gz"
      cwd "/tmp"
    end
    Chef::Log.info "Caylent-setup: Extracting drupal"
    execute "extract tar" do
      command "tar -xvzf drupal-#{node[:opsworks][:drupal][:version]}.tar.gz"
      cwd "/tmp"
    end
    Chef::Log.info "Caylent--setup: Removing word drupal/drupal-content folder"
    execute "remove drupal-content" do
      command "rm -R drupal/drupal-content"
      cwd "/tmp"
    end
  end
end
