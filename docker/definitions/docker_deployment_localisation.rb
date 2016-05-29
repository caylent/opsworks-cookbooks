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

  ruby_block "docker login" do
    #ToDo: Add logic for none ecr repo
    block do
        #tricky way to load this Chef::Mixin::ShellOut utilities
        Chef::Resource::RubyBlock.send(:include, Chef::Mixlib::ShellOut)
        command = Chef::Mixlib::ShellOut.new('aws ecr get-login')
        Chef::Log.info "aws cmd '#{command}'"
        command.run_command
        Chef::Log.info "shell out '#{command.stdout}'"
        node.set[:deploy][application][:docker_login] = command.stdout
    end
    action :run
  end



  Chef::Log.info "Attempting to login to ecr with command #node[:docker_login]"
  execute "ecr login" do
    command "#{node[:deploy][application][:docker_login]}"
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
    command "docker stop #{node[:deploy][application][:environment_variables][:docker_version]}"
    ignore_failure true
  end

  # if (node[:deploy][application][:environment_variables][:db_reload] == "1")
  #   Chef::Log.info "Caylent-Deploy: Attempting to run image with db reload"
  #   execute "copy docker framework" do
  #     command "docker run -e 'DBRELOAD=true' -p 80:80 -p 443:443 #{node[:deploy][application][:environment_variables][:docker_image]}:#{node[:deploy][application][:environment_variables][:docker_version]}"
  #   end
  # else
    Chef::Log.info "Caylent-Deploy: Attempting to run image"
    execute "copy docker framework" do
      #command "docker run -p 80:80 -p 443:443 #{node[:deploy][application][:environment_variables][:docker_image]}:#{node[:deploy][application][:environment_variables][:docker_version]}"
      command "docker -run #{node[:deploy][application][:environment_variables][:docker_image]}:#{node[:deploy][application][:environment_variables][:docker_version]}"
    end
  # end

 end

end
