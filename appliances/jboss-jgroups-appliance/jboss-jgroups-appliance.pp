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

import "jboss-jgroups-appliance"

# Information about our appliance
$appliance_name = "JBoss JGroups Appliance"
$appliance_version = "1.0.0.Beta2"

# Configuration
appliance_base::setup{$appliance_name:}
appliance_base::enable_updates{$appliance_name:}
banners::all{$appliance_name:}
firewall::setup{$appliance_name: status=>"disabled"}
console::site{$appliance_name: content_template=>"content.erb"}
ssh::setup{$appliance_name:}

include jboss-jgroups::appliance
