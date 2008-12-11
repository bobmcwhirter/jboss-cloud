
Summary: JBoss Rails
Name: jboss-rails
Version: %{version}
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: http://superb-east.dl.sourceforge.net/sourceforge/javagroups/JGroups-#{version}.bin.zip
BuildRoot: /tmp/%{name}

%define __jar_repack %{nil}

%description
The JBoss Rails deployer for AS5

%prep
%setup 

%install
## every config but minimal
#configs=( all  default  standard  web )

#for config in ${configs[@]} ; do
  #install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deployers/jboss-rails.deployer
  #cp -R ./jboss-rails.deployer $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deployers/
#done

#install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/server/default/deployers/jboss-rails.deployer
#cp -R ./jboss-rails.deployer $RPM_BUILD_ROOT/opt/jboss-as5/server/default/deployers/

#install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/server/web/deployers/jboss-rails.deployer
#cp -R ./jboss-rails.deployer $RPM_BUILD_ROOT/opt/jboss-as5/server/web/deployers/

%clean
rm -Rf $RPM_BUILD_ROOT

%pre

%files
%defattr(-,jboss,jboss)
/


