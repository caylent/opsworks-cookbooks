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
  
  if node[:opsworks][:layers].include?("nfs")
    Chef::Log.info "Caylent-Deploy: This stack contains a fs-teir"
    sharedPath = "#{node[:opsworks][:nfs][:export_full_path]}/#{application}"
  else
    Chef::Log.info "Caylent-Deploy:No fs_teir found, simulating fs share on local"
    sharedPath = node[:deploy][application][:shared_content_folder] 
  end
  
  
  #====================================
  # copies files to the shared folder
  #===================================
    Chef::Log.info "Caylent-deploy:Wordpress add copy from #{node[:deploy][application][:current_path]}/wp-content"
    Chef::Log.info "Caylent-deploy:Wordpress add copy to #{sharedPath}"
    execute "copy wordpress framework" do
      command "rsync --recursive --compress #{node[:deploy][application][:current_path]}/wp-content/* #{sharedPath}"
      only_if { File.exists?("#{node[:deploy][application][:current_path]}/wp-content")}
    end
    

    Chef::Log.info "Caylent-Deploy: Do Nothing"
    execute "remove and replace currentsymlink" do
      command "rm #{node[:deploy][application][:current_path]}"           #ToDo Current needs to be a symlink
    end
    
    link "#{node[:deploy][application][:current_path]}" do
      to "#{node[:deploy][application][:deploy_to]}/core_framwork"
      link_type :symbolic
      owner "deploy"
      group "www-data"
      mode "775"
    end
    
 
 
  


    directory "#{node[:deploy][application][:deploy_to]}/core_framwork/" do
      owner 'deploy'
      group 'www-data'
      mode '775'
    end
    
    Chef::Log.info "Caylent-Deploy: Running command cp /tmp/wordpress/* #{node[:deploy][application][:current_path]}/"
    execute "copy wordpress framework" do
      command "cp -r /tmp/wordpress/* #{node[:deploy][application][:deploy_to]}/core_framwork/"
    end
    
    Chef::Log.info "Caylent-Deploy:Creating wp-config.php file in #{node[:deploy][application][:current_path]}/wp-config.php"
    template "#{node[:deploy][application][:current_path]}/wp-config.php" do
      source "wp-config.php.erb"
      owner "root"
      mode 0644
      variables ({:application => node[:deploy][application]})
    end



    execute "copy wordpress framework" do
      command "rsync --recursive --compress -u #{node[:deploy][application][:current_path]}/wp-content/* #{sharedPath}"
    end    


    execute "copy wordpress framework" do
      command "cp -R #{node[:deploy][application][:current_path]}/wp-content/* #{sharedPath}"
    end    


    link "#{node[:deploy][application][:current_path]}/wp-content" do
      to "#{node[:deploy][application][:shared_content_folder]}"
      link_type :symbolic
      owner "deploy"
      group "www-data"
      mode "775"
    end
    
      
    Chef::Log.info "Caylent-Deploy: Running command chown -R deploy:www-data ./"
    execute "owner" do
      command "chown -R deploy:www-data ./"
      cwd "#{node[:deploy][application][:current_path]}/"
    end
    
    execute "change permissions on wordpress framework" do
      command "chmod -R 775 #{node[:deploy][application][:current_path]}"
    end

    Chef::Log.info "Caylent-Deploy: Checking for previous deployment by looking for #{sharedPath}/wp-content"
    
    deploy_action = "nothing"
    
    if (!File.exists?("#{sharedPath}"))
      Chef::Log.info "Caylent-Deploy:No previous version found on share"
      deploy_action = "add"
    end
    
    if (File.exists?("#{sharedPath}") && !node[:opsworks][:cms_framework][:overwite])
      Chef::Log.info "Caylent-Deploy:Previous version found on share updating application"
      deploy_action = "update"
    end
    
    if (File.exists?("#{sharedPath}") && node[:opsworks][:cms_framework][:overwite])
      Chef::Log.info "Caylent-Deploy:Previous version found on share and overwrite variable is set"
      deploy_action = "overwrite"
    end
    
    case deploy_action
      when "add"
        Chef::Log.info "Caylent-Deploy: Case Match for Add"
        add_wpcontent
        #check_for_sql_file
        remove_current_symlink
        setup_wordpress_framework
        link_wpcontent
        update_permissions
      
      when "update"
        Chef::Log.info "Caylent-Deploy: Case Match for Update"
        update_wpcontent
        #check_for_sql_file
        remove_current_symlink
        setup_wordpress_framework
        link_wpcontent
        update_permissions
        
      when "overwrite"
       Chef::Log.info "Caylent-Deploy: Case Match for Overwrite"
        
        overwrite_wpcontent
        #check_for_sql_file
        remove_current_symlink
        setup_wordpress_framework
        link_wpcontent
        update_permissions
      else
        Chef::Log.info "Caylent-deploy: No case matched so no other actions taken"
    end
    
  
  deploy_cms_framework
end

