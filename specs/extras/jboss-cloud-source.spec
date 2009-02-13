
Summary: JBoss Cloud source
Name: jboss-cloud-source
Version: 1
Release: dev
License: LGPL
BuildArch: noarch
Group: Applications/System
BuildRoot: /tmp/%{name}

%description
JBoss Cloud source

%prep
/bin/rm -rf %{_topdir}/SOURCES/jboss-cloud

%install
/usr/bin/git clone git://github.com/bobmcwhirter/jboss-cloud.git %{_topdir}/SOURCES/jboss-cloud
mkdir -p $RPM_BUILD_ROOT/opt
cp -R %{_topdir}/SOURCES/jboss-cloud/ $RPM_BUILD_ROOT/opt/

%clean
rm -Rf $RPM_BUILD_ROOT

%post
/bin/cp /etc/sudoers /etc/sudoers.orig
/bin/echo "oddthesis ALL = NOPASSWD: /usr/bin/appliance-creator" >> /etc/sudoers
/bin/echo "Defaults:oddthesis env_keep+=\"PYTHONUNBUFFERED\"" >> /etc/sudoers

%preun
/bin/rm /etc/sudoers
/bin/cp /etc/sudoers.orig /etc/sudoers

%files
%defattr(-,root,root)
/


