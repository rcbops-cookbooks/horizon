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

default["horizon"]["theme_image_base"] = "http://ef550cb0f0ed69a100c1-40806b80b9b0290f6d33c73b927ee053.r51.cf2.rackcdn.com"

# The endpoint type to use from the Keystone service catalog
default["horizon"]["endpoint_type"] = "internalURL"

case node["platform"]
when "fedora", "centos", "redhat", "amazon", "scientific"
  default["horizon"]["ssl"]["dir"] = "/etc/pki/tls"
  default["horizon"]["local_settings_path"] = "/etc/openstack-dashboard/local_settings"
  # TODO(shep) - Fedora does not generate self signed certs by default
  default["horizon"]["platform"] = {
    "supporting_packages" => ["MySQL-python", "python-cinderclient",
      "python-quantumclient", "python-keystoneclient", "python-glanceclient",
      "python-novaclient"],
    "horizon_packages" => ["openstack-dashboard", "python-netaddr"],
    "package_overrides" => ""
  }
  default["horizon"]["dash_path"] = "/usr/share/openstack-dashboard"
  default["horizon"]["stylesheet_path"] =
    "/usr/share/openstack-dashboard/openstack_dashboard/templates/_stylesheets.html"
  default["horizon"]["wsgi_path"] = node["horizon"]["dash_path"] + "/openstack_dashboard/wsgi"
when "ubuntu", "debian"
  default["horizon"]["ssl"]["dir"] = "/etc/ssl"
  default["horizon"]["local_settings_path"] = "/etc/openstack-dashboard/local_settings.py"
  default["horizon"]["platform"] = {
    "supporting_packages" => ["python-mysqldb", "python-cinderclient",
      "python-quantumclient", "python-keystoneclient", "python-glanceclient",
      "python-novaclient"],
    "horizon_packages" => ["lessc", "openstack-dashboard", "python-netaddr"],
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
  default["horizon"]["dash_path"] = "/usr/share/openstack-dashboard/openstack_dashboard"
  default["horizon"]["stylesheet_path"] =
    "/usr/share/openstack-dashboard/openstack_dashboard/templates/_stylesheets.html"
  default["horizon"]["wsgi_path"] = node["horizon"]["dash_path"] + "/wsgi"
end
