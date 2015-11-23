#===============================================================================#
# FILE: drupal_deployment.rb
#===============================================================================#
# PURPOSE: This is the primary deployment script for drupal deployments 
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1. 
#===============================================================================# 

node[:deploy].each do |application, deploy|

  Chef::Log.info "Caylent-deploy:Running app_deploy_main for #{application}. The full details are #{node[:deploy][application]}"
  
  
  # ToDo Update this to better reflect purpose of standardised test url for ELB
  Chef::Log.info "Caylent-deploy:Testing for required info.php file in web root"
  if !File.exists?("#{node[:deploy][application][:current_path]}/info.php")
    Chef::Log.error "Caylent-deploy:No #{node[:deploy][application][:current_path]}/info.php file. This is needed for the load balancer. Please check it is added to repo"
  end
  
  Chef::Log.info "Caylent-deploy:Deploying a drupal app"   
  drupal_deployment_localisation do
    application_name application
  end
  
end
