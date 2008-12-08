Summary: JBoss Rails
Name: jboss-rails
Version: 1.0.Beta3
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: jboss-rails-deployer.jar
BuildRoot: /tmp/%{name}-root

%description
The JBoss Rails deployer for AS5

%prep
%setup -c jboss-rails.deployer 

%install
echo "install in $PWD"

install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/server/default/deployers/jboss-rails.deployer
cp -R . $RPM_BUILD_ROOT/opt/jboss-as5/server/default/deployers/jboss-rails.deployer

install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/server/web/deployers/jboss-rails.deployer
cp -R . $RPM_BUILD_ROOT/opt/jboss-as5/server/web/deployers/jboss-rails.deployer

install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/server/all/deployers/jboss-rails.deployer
cp -R . $RPM_BUILD_ROOT/opt/jboss-as5/server/all/deployers/jboss-rails.deployer

%clean
rm -Rf $RPM_BUILD_ROOT

%pre

%files
%defattr(-,jboss,jboss)
/


