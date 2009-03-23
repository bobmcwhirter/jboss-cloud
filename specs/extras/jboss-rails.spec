
Summary: JBoss Rails
Name: jboss-rails
Version: 1.0.0.Beta4
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: http://repo.oddthesis.org/maven2/org/jboss/rails/jboss-rails/1.0.0.Beta4/jboss-rails-%{version}-deployer.jar
BuildRoot: /tmp/%{name}

%define __jar_repack %{nil}

%description
The JBoss Rails deployer for AS5

%prep
%setup -c jboss-rails.deployer -T

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


