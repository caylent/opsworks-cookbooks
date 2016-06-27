#===============================================================================#
# FILE: drupal_setup.rb
#===============================================================================#
# PURPOSE: This is the primary deployment script for drupal deployments 
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1. 
#
#===============================================================================# 

Chef::Log.info "Caylent-setup: Running drupal setup"

Chef::Log.info "Caylent-setup: Attempting to run drupal_setup_download"   
drupal_setup_download do
  application_name application
end
