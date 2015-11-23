#===============================================================================#
# FILE: drupal_modify_local.rb
#===============================================================================#
# PURPOSE: Setup the application database configuration 
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1. Check for environment variable if not empty run 2 and 3
#   2. create symlink to nfs shared subfolder
#===============================================================================# 

define :drupal_deployment_localisation do

  application = params[:application_name]
  
  Chef::Log.info "Caylent-Deploy: Running drupal localise for #{application}."
  
  if(node[:opsworks][:layers].contains("fs-tier")
    Chef::Log.info "Caylent-Deploy: This stack contains a fs-teir"
    node[:deploy][application][:shared_content_folder] = "#{node[:opsworks][:fs_tier][:export_full_path]}/#{application}"
    
  else
      Chef::Log.info "Caylent-Deploy:No fs_teir found, simulating fs share on local"
  end
  
  deploy_cms_framework
       
end

def "remove_current_symlink"
  execute "remove and replace currentsymlink"
      command "rm #{node[:deploy][application][:current_path]} && mkdir #{node[:deploy][application][:current_path]}"
    end
end

def "setup_drupal_framework"

  Chef::Log.info "Caylent-Deploy: Running command cp /tmp/drupal/* #{node[:deploy][application][:current_path]}/"
  execute "copy drupal framework" do
    command "cp -r /tmp/drupal/* #{node[:deploy][application][:current_path]}/"
  end
  
  
  #ToDo replace with drupal template
  Chef::Log.info "Caylent-Deploy:Creating drupal-config.php file in #{node[:deploy][application][:current_path]}/drupal-config.php"
  template "#{node[:deploy][application][:current_path]}/drupal-config.php" do
    source "drupal-config.php.erb"
    owner "root"
    mode 0644
    variables ({:application => node[:deploy][application]})
  end

end

def "add_drupal"

  execute "copy drupal framework" do
    command "rync --recursive --compress #{node[:deploy][application][:current_path]}/ #{node[:deploy][application][:shared_content_folder]}"
  end
  
  
end

def "update_drupal"

  execute "copy drupal framework" do
    command "rync --recursive --compress -u #{node[:deploy][application][:current_path]}/ #{node[:deploy][application][:shared_content_folder]}"
  end
  
end

def "overwrite_drupal"

  execute "copy drupal framework" do
    command "cp -R #{node[:deploy][application][:current_path]}/ #{node[:deploy][application][:shared_content_folder]}"
  end
  
end

def "link_drupal"

  execute "create symlink" do
    command " ln -s #{node[:deploy][application][:shared_content_folder]} #{node[:deploy][application][:current_path]}/"
  end
end
    
def "update_permissions"
  Chef::Log.info "Caylent-Deploy: Running command chown -R deploy:www-data ./"
  execute "owner" do
    command "chown -R deploy:www-data ./"
    cwd "#{node[:deploy][application][:current_path]}/"
  end
  
  execute "change permissions on drupal framework" do
    command "chmod -R 775 #{node[:deploy][application][:current_path]}"
  end
end

def "deploy_cms_framework"
  Chef::Log.info "Caylent-Deploy: Checking for previous deployment"
  if(!File.exists("#{node[:deploy][application][:shared_content_folder]}/uploads" ) #ToDo this should not check drupal-config
      Chef::Log.info "Caylent-Deploy:No previous version found on share"
      
      setup_drupal_framework 
      update_drupal #ToDo this should hopefully just update files that have changed from vanilla install if not vanilla install is presented to user
      add_drupal
      #check_for_sql_file
      remove_current_symlink
      link_drupal
      update_permissions
    
    else if ( File.exists("#{node[:deploy][application][:shared_content_folder]}/uploads" && !node[:opsworks][:cms_framework][:overwite])
      Chef::Log.info "Caylent-Deploy:Previous version found on share updating application"
      update_drupal
      #check_for_sql_file
      remove_current_symlink
      #setup_drupal_framework
      link_drupal
      update_permissions
      
    else if ( File.exists("#{node[:deploy][application][:shared_content_folder]}/uploads" && node[:opsworks][:cms_framework][:overwite])
    
      Chef::Log.info "Caylent-Deploy:Previous version found on share and overwrite variable is set"
      overwrite_drupal
      #check_for_sql_file
      remove_current_symlink
      #setup_drupal_framework
      link_drupal
      update_permissions
    end
end

