
%define jboss_version 5.0.1.GA
%define __jar_repack %{nil}

Summary: JBoss Cloud profiles
Name: jboss-as5-cloud-profiles
Version: 1.0.0.Beta3
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: http://internap.dl.sourceforge.net/sourceforge/jboss/jboss-5.0.1.GA-jdk6.zip
Requires: jboss-as5
BuildRoot: /tmp/jboss-cloud-profiles-%{jboss_version}

%description
The JBoss AS 5 cloud profiles (cluster and group)

%prep
%setup -n jboss-%{jboss_version}

%install

# create directories
mkdir -p $RPM_BUILD_ROOT/opt/jboss-as5/server/cluster
mkdir -p $RPM_BUILD_ROOT/opt/jboss-as5/server/group

# copy profiles
cp -R %{_topdir}/BUILD/jboss-%{jboss_version}/server/default/* $RPM_BUILD_ROOT/opt/jboss-as5/server/group/
cp -R %{_topdir}/BUILD/jboss-%{jboss_version}/server/all/* $RPM_BUILD_ROOT/opt/jboss-as5/server/cluster/

%clean
rm -Rf $RPM_BUILD_ROOT

%files
%defattr(-,jboss,jboss)
/

%changelog
* Tue Mar 03 2009 Marek Goldmann 5.0.1.GA-1
- JBoss AS version upgrade to 5.0.1.GA
