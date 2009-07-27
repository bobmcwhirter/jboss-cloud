
%define jboss_version 5.1.0.GA
%define __jar_repack %{nil}

Summary: JBoss Cloud profiles
Name: jboss-as5-cloud-profiles
Version: 1.0.0.Beta4
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: http://internap.dl.sourceforge.net/sourceforge/jboss/jboss-5.1.0.GA-jdk6.zip
Source1: jboss-as5-5.1.0.GA-cloud-gossip.patch
Requires: jboss-as5
BuildRequires: patch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

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

rm -Rf $RPM_BUILD_ROOT/opt/jboss-as5/server/*/deploy/ROOT.war

cd $RPM_BUILD_ROOT/opt/jboss-as5
patch -p1 < %{SOURCE1}

%clean
rm -Rf $RPM_BUILD_ROOT

%files
%defattr(-,jboss,jboss)
/

%changelog
* Tue May 26 2009 Marek Goldmann 5.1.0.GA-1
- JBoss AS version upgrade to 5.1.0.GA

* Tue Mar 03 2009 Marek Goldmann 5.0.1.GA-1
- JBoss AS version upgrade to 5.0.1.GA
