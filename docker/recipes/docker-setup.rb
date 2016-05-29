#===============================================================================#
# FILE: docker_setup.rb
#===============================================================================#
# PURPOSE: This is the primary deployment script for docker deployments
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1.
#
#===============================================================================#

Chef::Log.info "Caylent-setup: Running docker setup"

Chef::Log.info "Caylent-setup: Attempting to run docker_setup_download"
docker_setup_download do
  application_name application
end
