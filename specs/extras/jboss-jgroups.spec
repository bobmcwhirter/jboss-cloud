
Summary: JBoss JGroups
Name: jboss-jgroups
Version: 2.6.8.GA
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Requires: shadow-utils
Source0: http://heanet.dl.sourceforge.net/sourceforge/javagroups/JGroups-%{version}.bin.zip
Source1: jgroups-gossip.init
BuildRoot: /tmp/%{name}

%define __jar_repack %{nil}

%description
JBoss JGroups

%prep
%setup -n JGroups-%{version}.bin

%install
mkdir -p $RPM_BUILD_ROOT/opt
cp -R . $RPM_BUILD_ROOT/opt/jboss-jgroups

install -d -m 755 $RPM_BUILD_ROOT%{_initrddir}
install -m 755 %{SOURCE1} $RPM_BUILD_ROOT%{_initrddir}/jgroups-gossip

touch $RPM_BUILD_ROOT/etc/jboss-jgroups.conf


#install -d -m 755 $RPM_BUILD_ROOT%{_initrddir}

%clean
rm -Rf $RPM_BUILD_ROOT

%pre
JGROUPS_SHELL=/bin/bash
/usr/sbin/groupadd -r jgroups 2>/dev/null || :
/usr/sbin/useradd -c 'JBoss JGroups' -r -s $JGROUPS_SHELL -d /opt/jboss-jgroups -g jgroups jgroups 2>/dev/null || :

%files
%defattr(-,jgroups,jgroups)
/


