############################################################
# Default Attributes file
############################################################
# Include the attributes for all docker recipes
############################################################



############################################################
# docker Setup Attributes
############################################################

#default[:opsworks][:docker][:version] = "4.3.1"

############################################################
# docker Deployment Attributes
############################################################

# Iterate through the applications passed by OpsWorks.
node[:deploy].each do |application, deploy|
  
end


