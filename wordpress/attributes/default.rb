############################################################
# Default Attributes file
############################################################
# Include the attributes for all wordpress recipes
############################################################



############################################################
# Wordpress Setup Attributes
############################################################

default[:opsworks][:wordpress][:version] = "4.5.3"

############################################################
# Wordpress Deployment Attributes
############################################################

# Iterate through the applications passed by OpsWorks.
node[:deploy].each do |application, deploy|

  if (node[:deploy][application][:environment_variables][:wp_prefix] == nil)
    Chef::Log.warn "Caylent-Deploy:No wp_prefix set using default wp_"
    default[:deploy][application][:wp_prefix] = "wp_"
  else
    default[:deploy][application][:wp_prefix] = node[:deploy][application][:environment_variables][:wp_prefix]
  end
  
  default[:deploy][application][:shared_content_folder] = "#{node[:deploy][application][:deploy_to]}/shared/wp-content"
  
end

default[:opsworks][:cms_framework][:overwite] = false #There might be a batter place for this


