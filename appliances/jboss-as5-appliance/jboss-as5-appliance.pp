#-- 
#  Copyright (C) 2008 Red Hat Inc.
#  
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#  
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#  
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#
# Author: Bryan Kearney <bkearney@redhat.com>
#--

#
# base thincrust appliance
#

# Modules used by the appliance
import "appliance_base"
import "banners"
import "firewall"
import "console"
import "ssh"

# Information about our appliance
$appliance_name = "JBoss AS5 Appliance"
$appliance_version = "0.0.1"

# Configuration
appliance_base::setup{$appliance_name:}
appliance_base::enable_updates{$appliance_name:}
banners::all{$appliance_name:}
firewall::setup{$appliance_name: status=>"disabled"}
console::site{$appliance_name: content_template=>"content.erb"}
ssh::setup{$appliance_name:}


group {"jboss":
    ensure => "present",
}

user {"jboss":
    groups => ["jboss"],
    membership => "minimum",
}

file {"/etc/gshadow":
	source => "puppet:///jbossas5/gshadow",
}

firewall_rule{"jboss": destination_port=>"8080"}

augeas{"jbossasconf":
    context => "/files",
    changes => [
        "set /etc/jboss-as5.conf/JBOSS_IP $ipaddress",
        "set /etc/jboss-as5.conf/JAVA_HOME /usr"        
    ],
    load_path => "${ace_home}lenses",
}

service {"jboss-as5":
    ensure => running,
    enable => true,
    hasstatus => false,
    require => Augeas["jbossasconf"]
}
