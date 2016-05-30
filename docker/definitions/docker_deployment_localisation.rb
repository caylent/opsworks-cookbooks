#===============================================================================#
# FILE: docker_deployment_localisation.rb
#===============================================================================#
# PURPOSE: Setup the application database configuration
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1. Check for environment variable if not empty run 2 and 3
#   2. create symlink to nfs shared subfolder
#===============================================================================#

# Better code would be to build command for execution later this could include adding additional env variable to container
# Todo: Add logic forshared File storage
# Todo Logic to allow more than one docker container for port 80

define :docker_deployment_localisation do

  application = params[:application_name]

  Chef::Log.info "Caylent-Deploy: Running docker localise for #{application}."

  Chef::Log.info "Installing awscli using python-pip"
  execute "pip install awscli" do
    command "pip install awscli"
  end

  Chef::Log.info "AWS env variables"
  ENV['AWS_ACCESS_KEY_ID'] = node[:deploy][application][:environment_variables][:AWS_ACCESS_KEY_ID]
  ENV['AWS_SECRET_ACCESS_KEY'] = node[:deploy][application][:environment_variables][:AWS_SECRET_ACCESS_KEY]
  ENV['AWS_DEFAULT_REGION'] = node[:deploy][application][:environment_variables][:AWS_DEFAULT_REGION]


  ruby_block "docker login" do
    #ToDo: Add logic for none ecr repo
    block do
        #tricky way to load this Chef::Mixin::ShellOut utilities
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        command = 'aws ecr get-login'
        command_out = shell_out(command)
        node.default[:deploy][application][:docker_login] = command_out.stdout
    end
    action :run
  end

  Chef::Log.info "Attempting to login to ecr with command #node[:docker_login]"
  execute "ecr login" do
    command lazy { "#{node[:deploy][application][:docker_login]}" }
  end

  Chef::Log.info "Attempting to pull image"
  execute "docker pull for #{node[:deploy][application][:environment_variables][:docker_image]}:#{node[:deploy][application][:environment_variables][:docker_version]}" do
    command "docker pull #{node[:deploy][application][:environment_variables][:docker_image]}:#{node[:deploy][application][:environment_variables][:docker_version]}"
  end


 if (node[:deploy][application][:environment_variables][:ENV] == "prod")
  Chef::Log.info "Caylent-Deploy: Dirty fix for first boot"
  execute "stop old" do
    command "docker run -p 80:80 -p 443:443 #{node[:deploy][application][:environment_variables][:docker_image]}:#{node[:deploy][application][:environment_variables][:docker_version]}"
    ignore_failure true
  end
  Chef::Log.info "Caylent-Deploy: Dirty fix for first boot"
  execute "stop old" do
    command "docker stop #{node[:deploy][application][:environment_variables][:docker_version]} && docker run -n #{node[:deploy][application][:environment_variables][:docker_version]} -p 80:80 -p 443:443 #{node[:deploy][application][:environment_variables][:docker_image]}:#{node[:deploy][application][:environment_variables][:docker_version]}"
    ignore_failure false
  end
 else
  Chef::Log.info "Caylent-Deploy: Docker stop"
  execute "stop old" do
    command "docker stop #{node[:deploy][application][:environment_variables][:docker_image]}:#{node[:deploy][application][:environment_variables][:docker_version]}"
    ignore_failure true
  end

  # if (node[:deploy][application][:environment_variables][:db_reload] == "1")
  #   Chef::Log.info "Caylent-Deploy: Attempting to run image with db reload"
  #   execute "copy docker framework" do
  #     command "docker run -e 'DBRELOAD=true' -p 80:80 -p 443:443 #{node[:deploy][application][:environment_variables][:docker_image]}:#{node[:deploy][application][:environment_variables][:docker_version]}"
  #   end
  # else
    Chef::Log.info "Caylent-Deploy: Attempting to run image"
    execute "run image" do
      #command "docker run -p 80:80 -p 443:443 #{node[:deploy][application][:environment_variables][:docker_image]}:#{node[:deploy][application][:environment_variables][:docker_version]}"
      command "docker run #{node[:deploy][application][:environment_variables][:docker_image]}:#{node[:deploy][application][:environment_variables][:docker_version]}"
    end
  # end

 end

end
