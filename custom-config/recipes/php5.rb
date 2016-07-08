Chef::Log.info "Jcademy-Setup: Attempting update php.ini"
template "/etc/php5/apache2/php.ini" do
    source "php.ini.erb"
    owner "root"
    mode 0644
  end
