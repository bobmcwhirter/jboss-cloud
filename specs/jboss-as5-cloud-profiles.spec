%define jgroups_version 2.6.12.GA
%define jboss_version 5.1.0.GA
%define jboss_cache_version 3.2.1.GA

Summary:        JBoss Cloud profiles
Name:           jboss-as5-cloud-profiles
Version:        1.0.0.Beta7
Release:        1
License:        LGPL
BuildArch:      noarch
Group:          Applications/System
Source0:        http://internap.dl.sourceforge.net/sourceforge/jboss/jboss-%{jboss_version}-jdk6.zip
Source1:        jboss-as5-5.1.0.GA-cloud-gossip.patch
Source2:        http://heanet.dl.sourceforge.net/sourceforge/javagroups/JGroups-%{jgroups_version}.bin.zip
Source3:        jboss-as-5.1.0.GA-jbossws.patch
Source4:        http://downloads.sourceforge.net/project/jboss/JBossCache/JBossCache%20%{jboss_cache_version}/jbosscache-core-%{jboss_cache_version}-bin.zip
Requires:       jboss-as5
BuildRequires:  patch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
The JBoss AS 5 cloud profiles (cluster and group)

%define __jar_repack %{nil}

%prep
%setup -T -b 0 -n jboss-%{jboss_version}
%setup -T -b 2 -n JGroups-%{jgroups_version}.bin
%setup -T -b 4 -n jbosscache-core-%{jboss_cache_version}

%install
rm -Rf $RPM_BUILD_ROOT

cd %{_topdir}/BUILD

# create directories
mkdir -p $RPM_BUILD_ROOT/opt/jboss-as5/server/cluster
mkdir -p $RPM_BUILD_ROOT/opt/jboss-as5/server/group

# copy profiles
cp -R jboss-%{jboss_version}/server/default/* $RPM_BUILD_ROOT/opt/jboss-as5/server/group/
cp -R jboss-%{jboss_version}/server/all/* $RPM_BUILD_ROOT/opt/jboss-as5/server/cluster/

# install jgroups
cp JGroups-%{jgroups_version}.bin/jgroups-all.jar $RPM_BUILD_ROOT/opt/jboss-as5/server/cluster/lib/jgroups.jar

# install JBoss Cache
cp jbosscache-core-%{jboss_cache_version}/jbosscache-core.jar $RPM_BUILD_ROOT/opt/jboss-as5/server/cluster/lib/jbosscache-core.jar

rm -Rf $RPM_BUILD_ROOT/opt/jboss-as5/server/*/deploy/ROOT.war

cd $RPM_BUILD_ROOT/opt/jboss-as5
patch -p1 < %{SOURCE1}
patch -p1 < %{SOURCE3}

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
