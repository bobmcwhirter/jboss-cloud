# Kickstart file to build the JBoss AS5 Appliance

lang en_US.UTF-8
keyboard us
timezone US/Eastern
auth --useshadow --enablemd5
selinux --disabled
firewall --disabled
bootloader --timeout=1 --append="acpi=force"
network --bootproto=dhcp --device=eth0 --onboot=on
# Root password is thincrust
rootpw --iscrypted $1$uw6MV$m6VtUWPed4SqgoW6fKfTZ/

# 
# Partitoin Information. Change this as necessary
#
part / --size 1500 --fstype ext3 --ondisk sda

#
# Include the repositories
#
repo --name=thincrust --baseurl=http://www.thincrust.net/repo/noarch/

# Edit this next line after you have run rake rpm in the acex/rpm directory
repo --name=jboss-cloud --baseurl=file:///home/bob/thincrust/jboss-cloud/build-topdir/RPMS/noarch

repo --name=f10 --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-10&arch=$basearch 

#repo --name=f10-updates-newkey --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f9.newkey&arch=$basearch
#repo --name=jpackage6 --mirrorlist=http://www.jpackage.org/mirrorlist.php?dist=fedora-9&type=free&release=6.0

#
# Add all the packages after the base packages
#
%packages --excludedocs --nobase
    %include base-pkgs.ks
    #jpackage-release
    #jboxx
    #embedded-jopr
    jboss-as5
    jboss-rails
%end

#
# Add custom post scripts after the base post.
# 
%post
	/sbin/chkconfig --level 345 ace on
	/sbin/chkconfig --level 345 jboss-as5 on
	mkdir /etc/sysconfig/ace
	echo jboss-as5 >> /etc/sysconfig/ace/appliancename
	#cp /usr/share/ace/appliances/jboxx/logos/jbosssplash.xpm.gz /boot/grub/splash.xpm.gz
%end

