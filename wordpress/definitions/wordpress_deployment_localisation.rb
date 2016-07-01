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
    sharedPath = "#{node[:opsworks][:nfs][:mount_folder]}/#{application}"
  else
    Chef::Log.info "Caylent-Deploy:No fs_teir found, simulating fs share on local"
    sharedPath = node[:deploy][application][:shared_content_folder] 
  end
  
  
  #====================================
  # copies files to the shared folder
  #===================================
  def add_wpcontent(sharedPath, application)
    Chef::Log.info "Caylent-deploy:Wordpress add copy from #{node[:deploy][application][:current_path]}/wp-content"
    Chef::Log.info "Caylent-deploy:Wordpress add copy to #{node[:deploy][application][:shared_content_folder]}"
    execute "copy wordpress framework" do
      command "rsync --recursive --compress #{node[:deploy][application][:current_path]}/wp-content/* #{sharedPath}"
      only_if { File.exists?("#{node[:deploy][application][:current_path]}/wp-content")}
    end
    
  end

  def remove_current_symlink(application)
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
    
  end
 
 
  

  def setup_wordpress_framework(application)

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
  end


  def update_wpcontent(sharedPath, application)

    execute "copy wordpress framework" do
      command "rsync --recursive --compress -u #{node[:deploy][application][:current_path]}/wp-content/* #{sharedPath}"
    end    
  end

  def overwrite_wpcontent(sharedPath, application)

    execute "copy wordpress framework" do
      command "cp -R #{node[:deploy][application][:current_path]}/wp-content/* #{sharedPath}"
    end    
  end

  def link_wpcontent(application)

    link "#{node[:deploy][application][:current_path]}/wp-content" do
      to "#{node[:deploy][application][:shared_content_folder]}"
      link_type :symbolic
      owner "deploy"
      group "www-data"
      mode "775"
    end
    
  end
      
  def update_permissions(application)
    Chef::Log.info "Caylent-Deploy: Running command chown -R deploy:www-data ./"
    execute "owner" do
      command "chown -R deploy:www-data ./"
      cwd "#{node[:deploy][application][:current_path]}/"
    end
    
    execute "change permissions on wordpress framework" do
      command "chmod -R 775 #{node[:deploy][application][:current_path]}"
    end
  end

  def deploy_cms_framework(sharedPath, application)
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
        add_wpcontent(sharedPath, application)
        #check_for_sql_file
        remove_current_symlink(application)
        setup_wordpress_framework(application)
        link_wpcontent(application)
        update_permissions(application)
      
      when "update"
        Chef::Log.info "Caylent-Deploy: Case Match for Update"
        update_wpcontent(sharedPath, application)
        #check_for_sql_file
        remove_current_symlink(application)
        setup_wordpress_framework(application)
        link_wpcontent(application)
        update_permissions(application)
        
      when "overwrite"
       Chef::Log.info "Caylent-Deploy: Case Match for Overwrite"
        
        overwrite_wpcontent(sharedPath)
        #check_for_sql_file
        remove_current_symlink(application)
        setup_wordpress_framework(application)
        link_wpcontent(application)
        update_permissions(application)
      else
        Chef::Log.info "Caylent-deploy: No case matched so no other actions taken"
    end
    
  end
  
  deploy_cms_framework(sharedPath, application)
end

