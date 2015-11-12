#===============================================================================#
# FILE: wordpress_modify_local.rb
#===============================================================================#
# PURPOSE: Setup the application database configuration 
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1. Check for environment variable if not empty run 2 and 3
#   2. create symlink to nfs shared subfolder
#===============================================================================# 

define :wordpress_deployment_localisation do

  application = params[:application_name]
  
  Chef::Log.info "Caylent-Deploy: Running wordpress localise for #{application}."
  
  Chef::Log.info "Caylent-Deploy: Running command cp /tmp/wordpress/* #{node[:deploy][application][:current_path]}/"
  execute "copy wordpress framework" do
    command "cp -r /tmp/wordpress/* #{node[:deploy][application][:current_path]}/"
  end
  
  Chef::Log.info "Caylent-Deploy: Running command chown -R deploy:www-data ./"
  execute "copy wordpress framework" do
    command "chown -R deploy:www-data ./"
    cwd "#{node[:deploy][application][:current_path]}/"
  end
  
  Chef::Log.info "Caylent-Deploy:Creating wp-config.php file in #{node[:deploy][application][:current_path]}/wp-config.php"
  template "#{node[:deploy][application][:current_path]}/wp-config.php" do
    source "wp-config.php.erb"
    owner "root"
    mode 0644
    variables ({:application => node[:deploy][application]})
  end
  
end
