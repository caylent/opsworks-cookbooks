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
  
  if node[:opsworks][:layers].contains("fs-tier")
    Chef::Log.info "Caylent-Deploy: This stack contains a fs-teir"
    node[:deploy][application][:shared_content_folder] = "#{node[:opsworks][:fs_tier][:export_full_path]}/#{application}"
  else
    Chef::Log.info "Caylent-Deploy:No fs_teir found, simulating fs share on local"
  end
  
  deploy_cms_framework
       


  def remove_current_symlink
    execute "remove and replace currentsymlink"
      command "rm #{node[:deploy][application][:current_path]} && mkdir #{node[:deploy][application][:current_path]}"
    end
  end

  def setup_wordpress_framework

    Chef::Log.info "Caylent-Deploy: Running command cp /tmp/wordpress/* #{node[:deploy][application][:current_path]}/"
    execute "copy wordpress framework" do
      command "cp -r /tmp/wordpress/* #{node[:deploy][application][:current_path]}/"
    end
    
    Chef::Log.info "Caylent-Deploy:Creating wp-config.php file in #{node[:deploy][application][:current_path]}/wp-config.php"
    template "#{node[:deploy][application][:current_path]}/wp-config.php" do
      source "wp-config.php.erb"
      owner "root"
      mode 0644
      variables ({:application => node[:deploy][application]})
    end
  end

  def add_wpcontent

    execute "copy wordpress framework" do
      command "rync --recursive --compress #{node[:deploy][application][:current_path]}/wp-content #{node[:deploy][application][:shared_content_folder]}"
    end
  end

  def update_wpcontent

    execute "copy wordpress framework" do
      command "rync --recursive --compress -u #{node[:deploy][application][:current_path]}/wp-content #{node[:deploy][application][:shared_content_folder]}"
    end    
  end

  def overwrite_wpcontent

    execute "copy wordpress framework" do
      command "cp -R #{node[:deploy][application][:current_path]}/wp-content #{node[:deploy][application][:shared_content_folder]}"
    end    
  end

  def link_wpcontent

    execute "create symlink" do
      command " ln -s #{node[:deploy][application][:shared_content_folder]} #{node[:deploy][application][:current_path]}/wp-content"
    end
  end
      
  def update_permissions
    Chef::Log.info "Caylent-Deploy: Running command chown -R deploy:www-data ./"
    execute "owner" do
      command "chown -R deploy:www-data ./"
      cwd "#{node[:deploy][application][:current_path]}/"
    end
    
    execute "change permissions on wordpress framework" do
      command "chmod -R 775 #{node[:deploy][application][:current_path]}"
    end
  end

  def deploy_cms_framework
    
    
    if (!File.exists("#{node[:deploy][application][:shared_content_folder]}/uploads"))
      Chef::Log.info "Caylent-Deploy:No previous version found on share"
      deploy_action = "add"
    end
    
    if (File.exists("#{node[:deploy][application][:shared_content_folder]}/uploads") && !node[:opsworks][:cms_framework][:overwite])
      Chef::Log.info "Caylent-Deploy:Previous version found on share updating application"
      deploy_action = "update"
    end
    
    if (File.exists("#{node[:deploy][application][:shared_content_folder]}/uploads") && node[:opsworks][:cms_framework][:overwite])
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
    
  end
end

