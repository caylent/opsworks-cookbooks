############################################################
# Default Attributes file
############################################################
# Include the attributes for all drupal recipes
############################################################



############################################################
# Wordpress Setup Attributes
############################################################

default[:opsworks][:drupal][:version] = "4.3.1"

############################################################
# Wordpress Deployment Attributes
############################################################

# Iterate through the applications passed by OpsWorks.
node[:deploy].each do |application, deploy|

  if (node[:deploy][application][:environment_variables][:drupal_prefix] == nil)
    Chef::Log.warn "Wizkru-Deploy:No drupal_prefix set using default drupal_"
    default[:deploy][application][:drupal_prefix] = "drupal_"
  else
    default[:deploy][application][:drupal_prefix] = node[:deploy][application][:environment_variables][:drupal_prefix]
  end
  
  default[:deploy][application][:shared_content_folder] = "#{node[:opsworks][:deploy][:appdirectory]}/shared/drupal-content"
  
end




