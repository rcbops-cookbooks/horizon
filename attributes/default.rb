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

# Set the name of the user which will own the processes and files
default["horizon"]["horizon_user"] = "horizon"
default["horizon"]["rax_logo"] = true

# Setup Database creds
default["horizon"]["db"]["username"] = "dash"
default["horizon"]["db"]["password"] = "dash"
default["horizon"]["db"]["name"] = "dash"

# General SSL Setup
default["horizon"]["use_ssl"] = true
default["horizon"]["ssl"]["cert"] = "horizon.pem"
default["horizon"]["ssl"]["key"] = "horizon.key"
default["horizon"]["ssl"]["chain"] = nil

# Horizon Services
default["horizon"]["services"]["dash"]["scheme"] = "http"
default["horizon"]["services"]["dash"]["network"] = "public"
default["horizon"]["services"]["dash"]["port"] = 80
default["horizon"]["services"]["dash"]["path"] = "/"

# Horizon SSL Services
default["horizon"]["services"]["dash_ssl"]["scheme"] = "https"
default["horizon"]["services"]["dash_ssl"]["network"] = "public"
default["horizon"]["services"]["dash_ssl"]["port"] = 443
default["horizon"]["services"]["dash_ssl"]["path"] = "/"

# Neutron Options
default["horizon"]["neutron"]["enable_lb"] = "False"

# Enable / Disable Swift panel
default["horizon"]["swift"]["enabled"] = "False"

# Set Default Theme, Supports "default" or "ubuntu"
default["horizon"]["theme"] = "default"

# Set Site Branding/Title
default["horizon"]["site_branding"] = "OpenStack Dashboard"

# Options Customize the theme images
default["horizon"]["theme_image_update_style"] = false
default["horizon"]["theme_image_base"] = nil
default["horizon"]["theme_image_list"] = nil

# Options Customize the theme css
default["horizon"]["theme_css_update_style"] = false
default["horizon"]["theme_css_base"] = nil
default["horizon"]["theme_css_list"] = nil

# Set the Help URL in Horizon
default["horizon"]["help_url"] = "http://www.rackspace.com/knowledge_center/product-page/rackspace-private-cloud"

# Enable Password Auto Complete
default["horizon"]["password_autocomplete"] = "on"

# domains that horizon accepts traffic to (http://myopenstackdashboard.com, for example)
default["horizon"]["allowed_hosts"] = nil # set to an array of strings if you want to lock horizon down.

# The endpoint type to use from the Keystone service catalog
default["horizon"]["endpoint_type"] = "internalURL"
default["horizon"]["endpoint_host"] = nil
default["horizon"]["endpoint_port"] = nil
default["horizon"]["endpoint_scheme"] = nil

# Set platform options
default["horizon"]["secret_key"] = "/etc/openstack-dashboard/secret_key"
default["horizon"]["stylesheet_path"] = "/usr/share/openstack-dashboard/openstack_dashboard/templates/_stylesheets.html"

case node["platform"]
  when "fedora", "centos", "redhat", "amazon", "scientific"
    default["horizon"]["dash_path"] = "/usr/share/openstack-dashboard"
    default["horizon"]["wsgi_path"] = node["horizon"]["dash_path"] + "/openstack_dashboard/wsgi"
    default["horizon"]["ssl"]["dir"] = "/etc/pki/tls"
    default["horizon"]["local_settings_path"] = "/etc/openstack-dashboard/local_settings"
    default["horizon"]["platform"] = {
      "supporting_packages" => ["MySQL-python",
                                "python-cinderclient",
                                "python-neutronclient",
                                "python-keystoneclient",
                                "python-glanceclient",
                                "python-novaclient",
                                "python-django-compressor"],
      "horizon_packages" => ["openstack-dashboard",
                             "python-netaddr",
                             "nodejs-less"],
      "package_options" => ""
    }
  when "ubuntu", "debian"
    default["horizon"]["dash_path"] = "/usr/share/openstack-dashboard/openstack_dashboard"
    default["horizon"]["wsgi_path"] = node["horizon"]["dash_path"] + "/wsgi"
    default["horizon"]["ssl"]["dir"] = "/etc/ssl"
    default["horizon"]["local_settings_path"] = "/etc/openstack-dashboard/local_settings.py"
    default["horizon"]["platform"] = {
      "supporting_packages" => ["python-mysqldb",
                                "python-cinderclient",
                                "python-neutronclient",
                                "python-keystoneclient",
                                "python-glanceclient",
                                "python-novaclient",
                                "python-compressor"],
      "horizon_packages" => ["openstack-dashboard",
                             "python-netaddr",
                             "node-less"],
      "package_options" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
    }
end
