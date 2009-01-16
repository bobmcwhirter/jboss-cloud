%define jboss_version 5.0.0.GA
%define __jar_repack %{nil}

Summary: JBoss Cloud profiles
Name: jboss-as5-cloud-profiles
Version: 1.0.0.Beta2
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: http://internap.dl.sourceforge.net/sourceforge/jboss/jboss-%{jboss_version}-jdk6.zip
Requires: jboss-as5
BuildRoot: /tmp/jboss-cloud-profiles-%{jboss_version}

%description
The JBossAS 5 cloud profiles (cluster and group)

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

%pre
#JBOSS_SHELL=/bin/bash
#/usr/sbin/groupadd -r jboss 2>/dev/null || :
#/usr/sbin/useradd -c JBossAS -r -s $JBOSS_SHELL -d /opt/jboss-as5 -g jboss jboss 2>/dev/null || :

%files
%defattr(-,jboss,jboss)
/
#%attr(0755,root,root) %{_initrddir}/%{name}
#%attr(0755,root,root) /etc/jboss-as5.conf


