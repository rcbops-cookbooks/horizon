Support
=======

Issues have been disabled for this repository.  
Any issues with this cookbook should be raised here:

[https://github.com/rcbops/chef-cookbooks/issues](https://github.com/rcbops/chef-cookbooks/issues)

Please title the issue as follows:

[horizon]: \<short description of problem\>

In the issue description, please include a longer description of the issue, along with any relevant log/command/error output.  
If logfiles are extremely long, please place the relevant portion into the issue description, and link to a gist containing the entire logfile

Please see the [contribution guidelines](CONTRIBUTING.md) for more information about contributing to this cookbook.

Description
===========

Installs the Openstack dashboard (codename: horizon) from packages.

http://nova.openstack.org

Requirements
============

Chef 0.10.0 or higher required (for Chef environment use).

Platforms
--------

* CentOS >= 6.4
* Ubuntu >= 12.04

Cookbooks
---------

The following cookbooks are dependencies:

* apache2
* database
* mysql
* osops-utils

Resources/Providers
===================

None


Recipes
=======

default
----
* includes recipe `server`  

server
----
* includes recipes `apache2`, `apache2:mod_wsgi`, `apache2:mod_rewrite`, `apache2:mod_ssl`
* installs and configures the openstack dashboard package, sets up the horizon database schema/user, and installs an appropriate apache config/site file  
* if `["horizon"]["theme"] = "Rackspace"`, will also install the Rackspace stylesheet, and grab the necessary branded jpegs  
* uses chef search to discover details of where the database (default mysql) and keystone api are installed so we don't need to explicitly set them in our attributes file for this cookbook  



Attributes 
==========
* `horizon['horizon_user']` - horizon system user
* `horizon["rax_logo"]` - Change default horizon logo to rax logo (true || false)
* `horizon["site_branding"]` - Set the site branding/title

* `horizon["db"]["name"]` - name of horizon database
* `horizon["db"]["username"]` - username for horizon database access
* `horizon["db"]["password"]` - password for horizon database access

* `horizon["use_ssl"]` - toggle for using ssl with dashboard (default true)
* `horizon["ssl"]["cert"]` - name to use when creating the ssl certificate
* `horizon["ssl"]["key"]` - name to use when creating the ssl key
* `horizon["ssl"]["cert_override"]` - location for custom Cert file
* `horizon["ssl"]["key_override"]` - location for custom Key file

* `horizon["services"]["dash"]["scheme"]` - defaults to http
* `horizon["services"]["dash"]["network"]` - `osops_networks` network name which service operates on
* `horizon["services"]["dash"]["port"]` - port to bind service to
* `horizon["services"]["dash"]["path"]` - URI to use

* `horizon["services"]["dash_ssl"]["scheme"]` - defaults to https
* `horizon["services"]["dash_ssl"]["network"]` - `osops_networks` network name which service operates on
* `horizon["services"]["dash_ssl"]["port"]` - port to bind service to
* `horizon["services"]["dash_ssl"]["path"]` - URI to use

* `horizon["horizon_user"] - Set the name of the use that Horizon will use, Normally "Horizon"

* `horizon["swift"]["enabled"]` - enable if swift endpoint is available

* `horizon["theme"]` - which theme to use for the dashboard. Supports "default" or "Rackspace"

* `horizon["platform"]` - Hash of platform specific package/service names and options

* `horizon["endpoint_type"]` - The endpoint type to use from the Keystone service catalog

Templates
=====

* `default_stylesheets.html.erb` - default stylesheet
* `dash-site.erb` - the apache config file for the dashboard vhost
* `local_settings.py.erb` - config file for the dashboard application
* `ports.conf.erb` - Apache ports.conf file
* `rs_stylesheets.html.erb` - Rackspace stylesheet

License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)  
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)  
Author:: Ron Pedde (<ron.pedde@rackspace.com>)  
Author:: Joseph Breu (<joseph.breu@rackspace.com>)  
Author:: William Kelly (<william.kelly@rackspace.com>)  
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)  
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)  
Author:: Matt Thompson (<matt.thompson@rackspace.co.uk>)  
Author:: Andy McCrae (<andrew.mccrae@rackspace.co.uk>)
Author:: Kevin Carter (kevin.carter@rackspace.com)
Author:: Zack Feldstein (zack.feldstein@racksapce.com)

Copyright 2012-2013, Rackspace US, Inc.  

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
