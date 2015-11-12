#===============================================================================#
# FILE: wordpress_setup.rb
#===============================================================================#
# PURPOSE: This is the primary deployment script for wordpress deployments 
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1. 
#
#===============================================================================# 

Chef::Log.info "Caylent-setup: Running wordpress setup"

Chef::Log.info "Caylent-setup: Attempting to run wordpress_setup_download"   
wordpress_setup_download do
  application_name application
end
