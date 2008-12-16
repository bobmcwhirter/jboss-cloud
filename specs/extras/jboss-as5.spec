
#%define version 5.0.0.GA

Summary: JBoss 
Name: jboss-as5
Version: %{version}
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: http://voxel.dl.sourceforge.net/sourceforge/jboss/jboss-%{version}-jdk6.zip
Source1: jboss-as5.init
BuildRoot: /tmp/jboss-%{version}

%define runuser jboss
%define __jar_repack %{nil}

%description
The JBossAS 5 Java Application Server

%prep
%setup -n jboss-%{version}

%install
mkdir -p $RPM_BUILD_ROOT/opt
cp -R . $RPM_BUILD_ROOT/opt/jboss-as5
rm -Rf $RPM_BUILD_ROOT/opt/jboss-as5/server/*/deploy/ROOT.war


install -d -m 755 $RPM_BUILD_ROOT%{_initrddir}
install -m 755 %{SOURCE1} $RPM_BUILD_ROOT%{_initrddir}/%{name}

touch $RPM_BUILD_ROOT/etc/jboss-as5.conf


%clean
rm -Rf $RPM_BUILD_ROOT

%pre
JBOSS_SHELL=/bin/bash
/usr/sbin/groupadd -r jboss 2>/dev/null || :
/usr/sbin/useradd -c JBossAS -r -s $JBOSS_SHELL -d /opt/jboss-as5 -g jboss jboss 2>/dev/null || :

%files
%defattr(-,jboss,jboss)
/
#%attr(0755,root,root) %{_initrddir}/%{name}
#%attr(0755,root,root) /etc/jboss-as5.conf


