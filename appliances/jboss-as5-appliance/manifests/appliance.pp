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
# Author: Bob McWhirter <bob@jboss.org>
#--

class jboss-as5::appliance {

  group {"jboss":
    ensure => "present",
  }

  user {"jboss":
    groups => ["jboss"],
    membership => "minimum",
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
}
