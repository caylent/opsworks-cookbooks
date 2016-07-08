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

  #Ensure nothing changes on nfs layer. All nodes in nfs layer
  #are skipped
  if !node[:opsworks][:instance][:layers].include?("nfs")
    
    layerName = node[:opsworks][:instance][:layers][0]
    # Check instances have been added to layer
    if !node[:opsworks][:layers][layerName][:instances].nil? && !node[:opsworks][:layers][layerName][:instances].empty?
        Chef::Log.warn "Debug layer name #{layerName} #{node[:opsworks][:layers][layerName][:instances].first}"
        # Only perform migrations on a single appserver to avoid collisions.
        migration_instance = node[:opsworks][:layers][layerName][:instances].first[1]
        current_ip = node[:opsworks][:instance][:private_ip]
        if migration_instance[:private_ip] == current_ip
            Chef::Log.info "Master Set"
            master = true
        else
            Chef::Log.info "No match found master not set" 
            master = false
        end
    end

    
    Chef::Log.info "Caylent-Deploy: Running wordpress localise for #{application}."
    
    if node[:opsworks][:layers].include?("nfs")
      Chef::Log.info "Caylent-Deploy: This stack contains a nfs setting sharedPath to #{node[:opsworks][:nfs][:mount_folder]}"
      sharedPath = "#{node[:opsworks][:nfs][:mount_folder]}/#{application}"
    else
      Chef::Log.info "Caylent-Deploy:No fs_teir found, simulating fs share on local"
      sharedPath = node[:deploy][application][:shared_content_folder] 
    end
    
    
    #====================================
    # copies files to the shared folder
    #===================================
    def add_wpcontent(sharedPath, application)
      Chef::Log.info "Caylent-deploy.add_wpcontent:Wordpress add copy from #{node[:deploy][application][:current_path]}/wp-content"
      Chef::Log.info "Caylent-deploy.add_wpcontent:Wordpress add copy to #{sharedPath}"
      execute "copy wordpress framework" do
        command "rsync --recursive --compress #{node[:deploy][application][:current_path]}/wp-content/* #{sharedPath}"
        only_if { File.exists?("#{node[:deploy][application][:current_path]}/wp-content")}
      end
      
    end

    def remove_current_symlink(application)
      Chef::Log.info "Caylent-Deploy.remove_current_symlink: Remove symlink #{node[:deploy][application][:current_path]}"
      execute "remove and replace currentsymlink" do
        command "rm #{node[:deploy][application][:current_path]}"           #ToDo Current needs to be a symlink
      end
     
      Chef::Log.info "Caylent-Deploy: Symlink #{node[:deploy][application][:current_path]} to #{node[:deploy][application][:deploy_to]}/core_framwork"
      link "#{node[:deploy][application][:current_path]}" do
        to "#{node[:deploy][application][:deploy_to]}/core_framwork"
        link_type :symbolic
        owner "www-data"
        group "www-data"
        mode "775"
      end
      
    end
 
 
    

    def setup_wordpress_framework(application)

      directory "#{node[:deploy][application][:deploy_to]}/core_framwork/" do
        owner 'www-data'
        group 'www-data'
        mode '775'
      end
      
      cpCommand = "cp -r /tmp/wordpress/* #{node[:deploy][application][:deploy_to]}/core_framwork/ && cp /tmp/wordpress/.htaccess #{node[:deploy][application][:deploy_to]}/core_framwork/"
      Chef::Log.info "Caylent-Deploy.setup_wordpress_framework: Running command '#{cpCommand}"
      execute "copy wordpress framework" do
        command "#{cpCommand}"
      end
      
      Chef::Log.info "Caylent-Deploy.setup_wordpress_framework:Creating file #{node[:deploy][application][:current_path]}/wp-config.php"
      template "#{node[:deploy][application][:current_path]}/wp-config.php" do
        source "wp-config.php.erb"
        owner "root"
        mode 0644
        variables ({:application => node[:deploy][application]})
      end
    end


    def update_wpcontent(sharedPath, application)

      syncCommand = "rsync --recursive --compress -u #{node[:deploy][application][:current_path]}/wp-content/* #{sharedPath}" 
      
      Chef::Log.info "Caylent-Deploy.update_wpcontent: Running command '#{syncCommand}"
      execute "copy wordpress framework" do
        command "#{syncCommand}"
      end    
    end

    def overwrite_wpcontent(sharedPath, application)
      
        overwiteCommand = "cp -R #{node[:deploy][application][:current_path]}/wp-content/* #{sharedPath}" 

      Chef::Log.info "Caylent-Deploy.update_wpcontent: Running command '#{overwiteCommand}"
      execute "copy wordpress framework" do
        command "#{overwiteCommand}"
      end    
    end

    def link_wpcontent(sharedPath, application)

      Chef::Log.info "Caylent-Deploy.link_wpcontent: Symlink #{node[:deploy][application][:current_path]}/wp-content to #{sharedPath}/core_framwork"
      link "#{node[:deploy][application][:current_path]}/wp-content" do
        to "#{sharedPath}"
        link_type :symbolic
        owner "www-data"
        group "www-data"
        mode "775"
      end
      
    end
        
    def update_permissions(sharedPath, application)
      updateCommand = "chown -R www-data:www-data #{node[:deploy][application][:current_path]}/" 
      Chef::Log.info "Caylent-Deploy.update_permissions: Running command #{updateCommand}"
      execute "owner" do
        command "#{updateCommand}"
      end
      
      permissionsCommand = "chmod -R 775 #{node[:deploy][application][:current_path]}" 
      Chef::Log.info "Caylent-Deploy.update_permissions: Running command #{permissionsCommand}"
      execute "change permissions on wordpress framework" do
        command "#{permissionsCommand}"
      end

      updateSharedCommand = "chown -R www-data:www-data #{sharedPath}/" 
      Chef::Log.info "Caylent-Deploy.update_permissions: Running command #{updateSharedCommand}"
      execute "owner" do
        command "#{updateSharedCommand}"
      end
      
      permissionsSharedCommand = "chmod -R 775 #{sharedPath}" 
      Chef::Log.info "Caylent-Deploy.update_permissions: Running command #{permissionsSharedCommand}"
      execute "change permissions on wordpress framework" do
        command "#{permissionsSharedCommand}"
      end
      
    end

    def deploy_cms_framework(sharedPath, application, master)
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
          link_wpcontent(sharedPath, application)
          update_permissions(sharedPath, application)
        
        when "update"
          Chef::Log.info "Caylent-Deploy: Case Match for Update"
          if master 
            update_wpcontent(sharedPath, application)
          end
          #check_for_sql_file
          remove_current_symlink(application)
          setup_wordpress_framework(application)
          link_wpcontent(sharedPath, application)
          if master 
            update_permissions(sharedPath, application)
          end
          
        when "overwrite"
         Chef::Log.info "Caylent-Deploy: Case Match for Overwrite"
          
          if master 
            overwrite_wpcontent(sharedPath)
          end
          #check_for_sql_file
          remove_current_symlink(application)
          setup_wordpress_framework(application)
          link_wpcontent(sharedPath, application)
          if master 
            update_permissions(sharedPath, application)
          end
        else
          Chef::Log.info "Caylent-deploy: No case matched so no other actions taken"
      end
      
    end
    
    deploy_cms_framework(sharedPath, application, master)
  end
end

