Summary: TorqueBox
Name: torquebox
Version: 1.0.0.Beta13
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: http://repository.torquebox.org/maven2/releases/org/torquebox/torquebox-core/%{version}/torquebox-core-%{version}-deployer.jar 
Requires: jboss-as5
BuildRoot: /tmp/%{name}

%define __jar_repack %{nil}

%description
The Torquebox deployer for AS5

%prep
%setup -c torquebox.deployer -T

%install
## every config but minimal
configs=( all  default  standard  web )

for config in ${configs[@]} ; do
  install -d 755 $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deployers/
  cp %SOURCE0 $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deployers/
done

%clean
rm -Rf $RPM_BUILD_ROOT

%pre

%files
%defattr(-,jboss,jboss)
/

%changelog
* Tue Jun 23 2009 Marek Goldmann 1.0.0.Beta13
- Upgrade to version 1.0.0.Beta13

* Fri May 22 2009 Marek Goldmann 1.0.0.Beta11
- Update after project name change to TorqueBox

* Tue Apr 28 2009 Marek Goldmann 1.0.0.Beta6
- Upgrade to Beta6