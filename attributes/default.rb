default["horizon"]["db"]["username"] = "dash"                                               # node_attribute
default["horizon"]["db"]["password"] = "dash"                                               # node_attribute
default["horizon"]["db"]["name"] = "dash"                                                   # node_attribute

default["horizon"]["use_ssl"] = true                                                        # node_attribute
default["horizon"]["ssl"]["cert"] = "horizon.pem"                                           # node_attribute
default["horizon"]["ssl"]["key"] = "horizon.key"                                            # node_attribute

default["horizon"]["services"]["dash"]["scheme"] = "http"                       # node_attribute
default["horizon"]["services"]["dash"]["network"] = "public"                    # node_attribute
default["horizon"]["services"]["dash"]["port"] = 80                           # node_attribute
default["horizon"]["services"]["dash"]["path"] = "/"

default["horizon"]["services"]["dash_ssl"]["scheme"] = "https"                       # node_attribute
default["horizon"]["services"]["dash_ssl"]["network"] = "public"                    # node_attribute
default["horizon"]["services"]["dash_ssl"]["port"] = 443                           # node_attribute
default["horizon"]["services"]["dash_ssl"]["path"] = "/"

default["horizon"]["swift"]["enabled"] = "False"

default["horizon"]["theme"] = "default"

# The endpoint type to use from the Keystone service catalog
default["horizon"]["endpoint_type"] = "internalURL"

case node["platform"]
when "fedora", "centos", "redhat", "amazon", "scientific"
  default["horizon"]["ssl"]["dir"] = "/etc/pki/tls"                                         # node_attribute
  default["horizon"]["local_settings_path"] = "/etc/openstack-dashboard/local_settings"     # node_attribute
  # TODO(shep) - Fedora does not generate self signed certs by default
  default["horizon"]["platform"] = {                                                   # node_attribute
    "horizon_packages" => ["openstack-dashboard", "MySQL-python", "python-netaddr"],
    "package_overrides" => ""
  }
  default["horizon"]["dash_path"] = "/usr/share/openstack-dashboard"      # node_attribute
  default["horizon"]["stylesheet_path"] = "/usr/share/openstack-dashboard/openstack_dashboard/templates/_stylesheets.html"
  default["horizon"]["wsgi_path"] = node["horizon"]["dash_path"] + "/openstack_dashboard/wsgi"                    # node_attribute
when "ubuntu", "debian"
  default["horizon"]["ssl"]["dir"] = "/etc/ssl"                                             # node_attribute
  default["horizon"]["local_settings_path"] = "/etc/openstack-dashboard/local_settings.py"  # node_attribute
  default["horizon"]["platform"] = {                                                   # node_attribute
    "horizon_packages" => ["lessc","openstack-dashboard", "python-mysqldb"],
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
  default["horizon"]["dash_path"] = "/usr/share/openstack-dashboard/openstack_dashboard"      # node_attribute
  default["horizon"]["stylesheet_path"] = "/usr/share/openstack-dashboard/openstack_dashboard/templates/_stylesheets.html"
  default["horizon"]["wsgi_path"] = node["horizon"]["dash_path"] + "/wsgi"                    # node_attribute
end

