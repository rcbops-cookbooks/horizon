default["horizon"]["db"]["username"] = "dash"
default["horizon"]["db"]["password"] = "dash"
default["horizon"]["db"]["name"] = "dash"

default["horizon"]["use_ssl"] = true
default["horizon"]["ssl"]["cert"] = "horizon.pem"
default["horizon"]["ssl"]["key"] = "horizon.key"

default["horizon"]["services"]["dash"]["scheme"] = "http"
default["horizon"]["services"]["dash"]["network"] = "public"
default["horizon"]["services"]["dash"]["port"] = 80
default["horizon"]["services"]["dash"]["path"] = "/"

default["horizon"]["services"]["dash_ssl"]["scheme"] = "https"
default["horizon"]["services"]["dash_ssl"]["network"] = "public"
default["horizon"]["services"]["dash_ssl"]["port"] = 443
default["horizon"]["services"]["dash_ssl"]["path"] = "/"

default["horizon"]["swift"]["enabled"] = "False"

default["horizon"]["theme"] = "default"
default["horizon"]["theme_image_update_style"] = "download_list"
default["horizon"]["theme_image_base"] = "http://ef550cb0f0ed69a100c1-40806b80b9b0290f6d33c73b927ee053.r51.cf2.rackcdn.com"
default["horizon"]["theme_image_list"] = ["PrivateCloud.png", "Rackspace_Cloud_Company.png",
    "Rackspace_Cloud_Company_Small.png", "alert_red.png", "body_bkg.gif",
    "selected_arrow.png"]
default["horizon"]["theme_css_update_style"] = "cookbook_list"
default["horizon"]["theme_css_base"] = nil
case node["horizon"]["theme"]
when "ubuntu"
  default["horizon"]["theme_style_template"] = "ubuntu_stylesheets.html.erb"
  default["horizon"]["theme_css_list"] = nil
when "Rackspace"
  default["horizon"]["theme_style_template"] = "rs_stylesheets.html.erb"
  default["horizon"]["theme_css_list"] = ["folsom.css"]
else
  default["horizon"]["theme_style_template"] = "default_stylesheets.html.erb"
  default["horizon"]["theme_css_list"] = nil
end

default["horizon"]["help_url"] = "http://docs.openstack.org"
default["horizon"]["password_autocomplete"] = "off"
default["horizon"]["theme_image_base"] = "http://ef550cb0f0ed69a100c1-40806b80b9b0290f6d33c73b927ee053.r51.cf2.rackcdn.com"
# domains that horizon accepts traffic to (http://myopenstackdashboard.com, for example)
default["horizon"]["allowed_hosts"] = nil # set to an array of strings if you want to lock horizon down.

# The endpoint type to use from the Keystone service catalog
default["horizon"]["endpoint_type"] = "internalURL"
default["horizon"]["endpoint_host"] = nil
default["horizon"]["endpoint_port"] = nil
default["horizon"]["endpoint_scheme"] = nil

case node["platform"]
when "fedora", "centos", "redhat", "amazon", "scientific"
  default["horizon"]["ssl"]["dir"] = "/etc/pki/tls"
  default["horizon"]["secret_key"] = "/etc/openstack-dashboard/secret_key"
  default["horizon"]["local_settings_path"] = "/etc/openstack-dashboard/local_settings"
  # TODO(shep) - Fedora does not generate self signed certs by default
  default["horizon"]["platform"] = {
    "supporting_packages" => ["MySQL-python", "python-cinderclient", "python-neutronclient", "python-keystoneclient", "python-glanceclient", "python-novaclient"],
    "horizon_packages" => ["openstack-dashboard", "python-netaddr", "nodejs-less"],
    "package_options" => ""
  }
  default["horizon"]["dash_path"] = "/usr/share/openstack-dashboard"
  default["horizon"]["stylesheet_path"] = "/usr/share/openstack-dashboard/openstack_dashboard/templates/_stylesheets.html"
  default["horizon"]["wsgi_path"] = node["horizon"]["dash_path"] + "/openstack_dashboard/wsgi"
when "ubuntu", "debian"
  default["horizon"]["ssl"]["dir"] = "/etc/ssl"
  default["horizon"]["secret_key"] = "/etc/openstack-dashboard/secret_key"
  default["horizon"]["local_settings_path"] = "/etc/openstack-dashboard/local_settings.py"
  default["horizon"]["platform"] = {
    "supporting_packages" => ["python-mysqldb", "python-cinderclient",
      "python-neutronclient", "python-keystoneclient", "python-glanceclient",
      "python-novaclient"],
    "horizon_packages" => ["openstack-dashboard", "python-netaddr", "node-less"],
    "package_options" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
  default["horizon"]["dash_path"] = "/usr/share/openstack-dashboard/openstack_dashboard"
  default["horizon"]["stylesheet_path"] = "/usr/share/openstack-dashboard/openstack_dashboard/templates/_stylesheets.html"
  default["horizon"]["wsgi_path"] = node["horizon"]["dash_path"] + "/wsgi"
end
