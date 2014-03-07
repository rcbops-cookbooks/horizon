#
# Cookbook Name:: horizon
# Recipe:: server
#
# Copyright 2012-2013, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Workaround to install apache2 on a fedora machine with selinux set to
# enforcing
# TODO(breu): this should move to a subscription of the template from the
#             apache2 recipe and it should simply be a restorecon on the
#             configuration file(s) and not change the selinux mode
#

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

chef_gem "chef-rewind"
require 'chef/rewind'

execute "set-selinux-permissive" do
  command "/sbin/setenforce Permissive"
  action :run
  only_if "[ ! -e /etc/httpd/conf/httpd.conf ] && [ -e /etc/redhat-release ] &&
    [ $(/sbin/sestatus | grep -c '^Current mode:.*enforcing') -eq 1 ]"
end

platform_options = node["horizon"]["platform"]

# Bind to 0.0.0.0, but only if we're not using openstack-ha w/ a horizon-ha
# VIP, otherwise HAProxy will fail to start when trying to bind horizon VIP
if get_role_count("openstack-ha") > 0 and
  rcb_safe_deref(node, "vips.horizon-dash")
  listen_ip = get_bind_endpoint("horizon", "dash")["host"]
else
  listen_ip = "0.0.0.0"
end

include_recipe "apache2"
include_recipe "apache2::mod_wsgi"
include_recipe "apache2::mod_rewrite"
include_recipe "osops-utils::mod_ssl"

# now rewind the ports.conf template resource laid down by the
# apache2::default recipe
unless node['apache']['listen_ports'].include?("443")
  node.set['apache']['listen_ports'] = node['apache']['listen_ports'] + ["443"]
end

rewind "template[#{node["apache"]["dir"]}/ports.conf]" do
  source "ports.conf.erb"
  cookbook_name "horizon"
  owner "root"
  group node["apache"]["root_group"]
  variables(
    :apache_listen_ports => node["apache"]["listen_ports"].map { |p| p.to_i }.uniq,
    :listen_ip => listen_ip)
  mode 00644
  notifies :restart, "service[apache2]"
end

#
# Workaround to re-enable selinux after installing apache on a fedora machine that has
# selinux enabled and is currently permissive and the configuration set to enforcing.
# TODO(breu): get the other one working and this won't be necessary
#
execute "set-selinux-enforcing" do
  command "/sbin/setenforce Enforcing ; restorecon -R /etc/httpd"
  action :run
  only_if "[ -e /etc/httpd/conf/httpd.conf ] && [ -e /etc/redhat-release ] &&
    [ $(/sbin/sestatus | grep -c '^Current mode:.*permissive') -eq 1 ] &&
    [ $(/sbin/sestatus | grep -c '^Mode from config file:.*enforcing') -eq 1 ]"
end

ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint("keystone-api", "keystone", "service-api")
ks_internal_endpoint = get_access_endpoint("keystone-api", "keystone", "internal-api")

#creates db and user
#returns connection info
#defined in osops-utils/libraries
create_db_and_user(
  "mysql",
  node["horizon"]["db"]["name"],
  node["horizon"]["db"]["username"],
  node["horizon"]["db"]["password"]
)

mysql_connect_ip = get_mysql_endpoint["host"]

platform_options["supporting_packages"].each do |pkg|
  include_recipe "osops-utils::#{pkg}"
end

horizon_user = node['horizon']['horizon_user']

# Make Horizon User
user horizon_user do
  comment "Horizon User"
  system true
  home "/var/lib/openstack-dashboard"
  shell "/bin/false"
  supports :manage_home=>false
  action :create
  not_if "id #{horizon_user}"
end

# Make Openstack Dashboard Direcotries
directories = ["/usr/share/openstack-dashboard", "/etc/openstack-dashboard", "/var/lib/openstack-dashboard"]
directories.each do |dir|
  directory dir do
    owner horizon_user
    group horizon_user
    mode 00775
    subscribes :create, "package[openstack-dashboard]", :immediately
    action :create
  end
end

# TODO(breu) verify this on RPM install
case node["platform"]
when "ubuntu"
  # Install Lesscpy
  package "python-lesscpy" do
    options platform_options["package_options"]
    action :upgrade
  end
end

# If internal and service URI's are on same host and either is set for SSL
# Set the service proto to SSL
if node['horizon']['endpoint_scheme'].nil?
  if ks_internal_endpoint["host"] == ks_service_endpoint["host"]
    if [ks_internal_endpoint["scheme"],ks_service_endpoint["scheme"]].any?{|proto|
        proto == "https"
      }
      endpoint_scheme = "https"
    else
      endpoint_scheme = ks_service_endpoint["scheme"]
    end
  else
    endpoint_scheme = ks_service_endpoint["scheme"]
  end
else
  endpoint_scheme = node['horizon']['endpoint_scheme']
end

#Verify if password_autocomplete attr is set to either on or off
# If neither it will default to off
if ["on", "off"].include? node["horizon"]["password_autocomplete"].downcase
  #attr validated; set to what was supplied
  password_autocomplete = node["horizon"]["password_autocomplete"].downcase
else
  # attr validation failed. set to off
  Chef::Log.warn("Current package[horizon-server]: password_autocomplete attribute supplied as, "\
                 << node["horizon"]["password_autocomplete"]\
                 << " Value must be set to \"off\" or \"on\","\
                 " setting attribute to off")
  password_autocomplete = "off"
end

if node['horizon']['endpoint_host'].nil?
  endpoint_host = ks_service_endpoint["host"]
else
  endpoint_host = node['horizon']['endpoint_host']
end

if node["horizon"]["endpoint_port"].nil?
  endpoint_port = ks_service_endpoint["port"]
else
  endpoint_port = node["horizon"]["endpoint_port"]
end

template node["horizon"]["local_settings_path"] do
  source "local_settings.py.erb"
  owner horizon_user
  group horizon_user
  mode "0644"
  variables(
    :secret_key => node["horizon"]["secret_key"],
    :user => node["horizon"]["db"]["username"],
    :passwd => node["horizon"]["db"]["password"],
    :db_name => node["horizon"]["db"]["name"],
    :db_ipaddress => mysql_connect_ip,
    :use_ssl => node["horizon"]["use_ssl"],
    :keystone_api_ipaddress => endpoint_host,
    :service_port => endpoint_port,
    :service_protocol => endpoint_scheme,
    :admin_port => ks_admin_endpoint["port"],
    :admin_protocol => ks_admin_endpoint["scheme"],
    :swift_enable => node["horizon"]["swift"]["enabled"],
    :openstack_endpoint_type => node["horizon"]["endpoint_type"],
    :help_url => node["horizon"]["help_url"] ,
    :password_autocomplete => password_autocomplete,
    :allowed_hosts => node["horizon"]["allowed_hosts"] ? node["horizon"]["allowed_hosts"] : ["*"],
    :enable_lb => node["horizon"]["neutron"]["enable_lb"],
    :site_branding => node["horizon"]["site_branding"]
  )
  notifies :reload, "service[apache2]", :immediately
end

platform_options["horizon_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

if node["horizon"]["rax_logo"] == true
  logos = ["logo.png", "logo-splash.png"]
  location = "/usr/share/openstack-dashboard/static/dashboard/img"
  logos.each do |img|
    cookbook_file "#{location}/#{img}" do
      source "rpc.png"
      mode 0644
      owner horizon_user
      group horizon_user
    end
  end
end

execute "openstack-dashboard syncdb" do
  cwd "/usr/share/openstack-dashboard"
  environment({ 'PYTHONPATH' => '/etc/openstack-dashboard:/usr/share/openstack-dashboard:$PYTHONPATH' })
  command "python manage.py syncdb --noinput"
  action :nothing
  subscribes :run, "package[openstack-dashboard]"
end

# Set a node attribute for the horizon secrete Key
node.set_unless["horizon"]["horizon_key"] = secure_password(16)

# Lay down the secret key for Horizon
template node["horizon"]["secret_key"] do
  source "secret_key.erb"
  owner horizon_user
  group horizon_user
  mode "0600"
  variables(:key_set => node["horizon"]["horizon_key"])
  notifies :restart, "service[apache2]", :immediately
end

cookbook_file "#{node["horizon"]["ssl"]["dir"]}/certs/#{node["horizon"]["ssl"]["cert"]}" do
  source "horizon.pem"
  mode 0644
  owner "root"
  group "root"
end

case node["platform"]
when "ubuntu", "debian"
  grp = "ssl-cert"
else
  grp = "root"
end

cookbook_file "#{node["horizon"]["ssl"]["dir"]}/private/#{node["horizon"]["ssl"]["key"]}" do
  source "horizon.key"
  mode 0640
  owner "root"
  group grp
end

# stop apache bitching
directory "#{node["horizon"]["dash_path"]}/.blackhole" do
  owner "root"
  action :create
end

# this file is in the package - we need to delete
# it because we do it better
file "#{node["apache"]["dir"]}/conf.d/openstack-dashboard.conf" do
  action :delete
  backup false
end

# Allow us to override the default cert location.
unless node["horizon"]["ssl"].attribute?"cert_override"
  cert_location = "#{node["horizon"]["ssl"]["dir"]}/certs/#{node["horizon"]["ssl"]["cert"]}"
else
  cert_location = node["horizon"]["ssl"]["cert_override"]
end

unless node["horizon"]["ssl"].attribute?"key_override"
  key_location = "#{node["horizon"]["ssl"]["dir"]}/private/#{node["horizon"]["ssl"]["key"]}"
else
  key_location = node["horizon"]["ssl"]["key_override"]
end

unless node["horizon"]["ssl"]["chain"].nil?
  chain_location = "#{node["horizon"]["ssl"]["dir"]}/certs/#{node["horizon"]["ssl"]["chain"]}"
end
template value_for_platform(
  ["ubuntu", "debian", "fedora"] => {
    "default" => "#{node["apache"]["dir"]}/sites-available/openstack-dashboard"
  },
  "fedora" => {
    "default" => "#{node["apache"]["dir"]}/vhost.d/openstack-dashboard"
  },
  ["redhat", "centos"] => {
    "default" => "#{node["apache"]["dir"]}/conf.d/openstack-dashboard.conf"
  },
  "default" => {
    "default" => "#{node["apache"]["dir"]}/openstack-dashboard.conf"
  }
) do
    source "dash-site.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
      :use_ssl => node["horizon"]["use_ssl"],
      :apache_contact => node["apache"]["contact"],
      :ssl_cert_file => cert_location,
      :ssl_key_file => key_location,
      :ssl_cert_chain_file => chain_location,
      :apache_log_dir => node["apache"]["log_dir"],
      :django_wsgi_path => node["horizon"]["wsgi_path"],
      :dash_path => node["horizon"]["dash_path"],
      :wsgi_user => horizon_user,
      :wsgi_group => node["apache"]["group"],
      :http_port => node["horizon"]["services"]["dash"]["port"],
      :https_port => node["horizon"]["services"]["dash_ssl"]["port"],
      :listen_ip => listen_ip
    )
    notifies :reload, "service[apache2]", :immediately
  end

if platform?("debian", "ubuntu") then
  apache_site "000-default" do
    enable false
  end
elsif platform?("fedora") then
  apache_site "default" do
    enable false
  end
end

# enable the site
apache_site "openstack-dashboard" do
  enable true
end

# This is a dirty hack to deal with https://bugs.launchpad.net/nova/+bug/932468
directory "/var/www/.novaclient" do
  owner node["apache"]["user"]
  group node["apache"]["group"]
  mode "0755"
  action :create
end

# Allow the default Ubuntu theme to be used if desired
if node["horizon"]["theme"] == "ubuntu" && platform?("ubuntu")
  package "openstack-dashboard-ubuntu-theme" do
    action :upgrade
    only_if { platform?("ubuntu") }
  end
elsif node["horizon"]["theme"] == "ubuntu" && ! platform?("ubuntu")
  Chef::Application.fatal! "This platform does not have the Ubuntu theme available"
else
  package "openstack-dashboard-ubuntu-theme" do
    action :purge
    only_if { platform?("ubuntu") }
  end
end

# Replace the openstack_dashboard/templates/_stylesheets.html file with the
#  appropriate template file
template node["horizon"]["stylesheet_path"] do
  source "default_stylesheets.html.erb"
  mode 0644
  owner horizon_user
  group horizon_user
end

# Here we provide for updating the css files:
# node["horizon"]["theme_css_list"]
#   is an array of file names of css scripts to work with
# node["horizon"]["theme_css_update_style"] =
#   "cookbook_list" will assume that the list of files are available
#     as cookbook files
#   "download_list" will assume that the list of files must be downloaded
#     from node["horizon"]["theme_css_base"]
hattr = node["horizon"]
unless hattr["theme_css_list"].nil?
  if ! hattr["theme_css_base"].nil? && hattr["theme_css_update_style"] == true
    hattr["theme_css_list"].each do |cssfile|
      remote_file "#{hattr["dash_path"]}/static/dashboard/css/#{cssfile}" do
        source "#{hattr["theme_css_base"]}/#{cssfile}"
        mode "0644"
        owner horizon_user
        group horizon_user
        action :create
      end
    end
  end
end

# Here we provide for updating the image files:
# node["horizon"]["theme_image_list"]
#   is an array of file names of css scripts to work with
# node["horizon"]["theme_image_update_style"] =
#   "cookbook_list" will assume that the list of files are available
#     as cookbook files
#   "download_list" will assume that the list of files must be downloaded
#     from node["horizon"]["theme_image_base"]
unless hattr["theme_image_list"].nil?
  if ! hattr["theme_image_base"].nil? && hattr["theme_image_update_style"] == true
    hattr["theme_image_list"].each do |imgfile|
      remote_file "#{hattr["dash_path"]}/static/dashboard/img/#{imgfile}" do
        source "#{hattr["theme_image_base"]}/#{imgfile}"
        mode "0644"
        owner horizon_user
        group horizon_user
        action :create
      end
    end
  end
end
