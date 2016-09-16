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
  docker_url = "#{node[:deploy][application][:environment_variables][:docker_url]}"
  docker_application = "#{node[:deploy][application][:environment_variables][:docker_application]}"
  docker_version = "#{node[:deploy][application][:environment_variables][:docker_version]}"
  docker_containerName = "#{docker_application}-#{docker_version}"
  docker_repo_type = "#{node[:deploy][application][:environment_variables][:docker_repo_type]}"
  docker_username = "#{node[:deploy][application][:environment_variables][:docker_username]}"
  docker_password = "#{node[:deploy][application][:environment_variables][:docker_password]}"
  docker_email = "#{node[:deploy][application][:environment_variables][:docker_email]}"
  ports = "#{node[:deploy][application][:environment_variables][:ports]}"
  deploy_commands = "#{node[:deploy][application][:environment_variables][:deploy_commands]}"

  Chef::Log.info "Caylent-Deploy: Running docker localise for #{application}."

  Chef::Log.info "Installing awscli using python-pip"
  execute "pip install awscli" do
    command "pip install awscli"
  end

 case docker_repo_type
 when 'ecr'

  Chef::Log.info "AWS env variables"
  ENV['AWS_ACCESS_KEY_ID'] = node[:deploy][application][:environment_variables][:AWS_ACCESS_KEY_ID]
  ENV['AWS_SECRET_ACCESS_KEY'] = node[:deploy][application][:environment_variables][:AWS_SECRET_ACCESS_KEY]
  ENV['AWS_DEFAULT_REGION'] = node[:deploy][application][:environment_variables][:AWS_DEFAULT_REGION]

  ruby_block "docker login" do
    block do
        #tricky way to load this Chef::Mixin::ShellOut utilities
        Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
        command = 'aws ecr get-login'
        command_out = shell_out(command)
        node.default[:deploy][application][:docker_login] = command_out.stdout

        Chef::Log.info "Arg:Attempting to login to #{docker_repo_type} with command #{node[:deploy][application][:docker_login]}"
        #notifies :run, 'execute[docker-login]', :immediately
    end
    action :run
  end
 when 'docker', 'gcr', 'quay'
    if !docker_username.empty? && !docker_email.empty?
     node.default[:deploy][application][:docker_login] = "docker login -u #{docker_username} -p #{docker_password} -e #{docker_email}"
    else
     node.default[:deploy][application][:docker_login] = "docker login -u #{docker_username} -p #{docker_password}"
    end
 end

  Chef::Log.info "Attempting to login to #{docker_repo_type} with command #{node[:deploy][application][:docker_login]}"
  if !docker_username.empty?
    execute "docker-login" do
      command lazy { "#{node[:deploy][application][:docker_login]}" }
    end
  end


  Chef::Log.info "Attempting to pull image"
  execute "docker pull for #{docker_url}/#{docker_application}:#{docker_version}" do
    command "docker pull #{docker_url}/#{docker_application}:#{docker_version}"
  end

  env_commands = ""
  ports = ""
  deploy_commands = []
  node[:deploy][application][:environment_variables].each do |key, value|
    Chef::Log.info "Adding #{key} and #{value}"
    case key
    when "ports"
      value.split(",").each do |port|
        ports = "#{ports} -p #{port}"
      end
    when "deploy_commands"
      value.split(",").each do |command|
        deploy_commands.push(command)
      end
    else
      if !key.include? "docker_"
        env_commands = "#{env_commands} -e #{key}=#{value}"
      end
    end
  end

 if (node[:deploy][application][:environment_variables][:ENV] == "prod")
  Chef::Log.info "Caylent-Deploy: Dirty fix for first boot"
  execute "dirty-start" do
    command "docker run #{ports} #{env_commands} --name #{docker_containerName} #{docker_url}/#{docker_application}:#{docker_version}"
    ignore_failure true
  end
  Chef::Log.info "Caylent-Deploy: Dirty fix for first boot"
  execute "stop,rename old, start new" do
    command "docker stop #{docker_containerName} && docker rename #{docker_containerName}-old && docker run #{env_commands} -d -p 80:80 --name #{docker_containerName} #{docker_url}/#{docker_application}:#{docker_version}"
    ignore_failure false
  end
  deploy_commands.each.with_index(1) do |deploy_command, index|
    execute "stop old deploy commands" do
      command "docker rm #{docker_containerName}_#{index}-old; docker stop #{docker_containerName}_#{index} && docker rename #{docker_containerName}_#{index} #{docker_containerName}_#{index}-old"
      ignore_failure true
    end
    execute "deploy commands" do
      Chef::Log.info "Running #{deploy_command} in prod #{index}"
      docker_with_command = "docker run -d #{env_commands} #{ports} --name #{docker_containerName}_#{index} #{docker_url}/#{docker_application}:#{docker_version} #{deploy_command}"
      Chef::Log.info docker_with_command

      command docker_with_command
    end
  end
 else
  Chef::Log.info "Caylent-Deploy: Docker stop"
  execute "stop old" do
    command "docker rm #{docker_containerName}-old; docker stop #{docker_containerName} && docker rename #{docker_containerName} #{docker_containerName}-old"
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
    command "docker run -d #{env_commands} #{ports} --name #{docker_containerName} #{docker_url}/#{docker_application}:#{docker_version}"
  end
  # end
  deploy_commands.each.with_index(1) do |deploy_command, index|
    execute "deploy commands" do
      Chef::Log.info "Running #{deploy_command} non-prod with #{index}"
      docker_with_command = "docker run -d #{env_commands} #{ports} --name #{docker_containerName}_#{index} #{docker_url}/#{docker_application}:#{docker_version} #{deploy_command}"
      Chef::Log.info docker_with_command

      command docker_with_command
    end
  end

 end

end
