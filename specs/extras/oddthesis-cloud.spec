
Summary: Oddthesis JBoss Cloud source
Name: oddthesis-cloud
Version: 1
Release: dev
License: LGPL
BuildArch: noarch
Group: Applications/System
BuildRoot: /tmp/%{name}

%description
Oddthesis JBoss Cloud source

%prep
/bin/rm -rf %{_topdir}/SOURCES/jboss-cloud

%install
/usr/bin/git clone git://github.com/bobmcwhirter/jboss-cloud.git %{_topdir}/SOURCES/jboss-cloud
mkdir -p $RPM_BUILD_ROOT/opt
cp -R %{_topdir}/SOURCES/jboss-cloud/ $RPM_BUILD_ROOT/opt/

%clean
rm -Rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/


