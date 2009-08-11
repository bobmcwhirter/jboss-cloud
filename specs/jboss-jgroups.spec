Summary: JBoss JGroups
Name: jboss-jgroups
Version: 2.6.12.Beta2
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Requires: shadow-utils
#Source0: http://heanet.dl.sourceforge.net/sourceforge/javagroups/JGroups-%{version}.bin.zip
Source0: http://repo.oddthesis.org/bundles/JGroups-%{version}.bin.tar.gz
Source1: jgroups-gossip.init
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

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

echo 'JAVA_HOME=/usr/lib/jvm/jre' > $RPM_BUILD_ROOT/etc/jboss-jgroups.conf

%post
/bin/echo "echo JGROUPS_IP=\`ifconfig eth0 | awk '/inet addr/ {split (\$2,A,\":\"); print A[2]}'\` >> /etc/jboss-jgroups.conf" >> /etc/rc.local

%clean
rm -Rf $RPM_BUILD_ROOT

%pre
JGROUPS_SHELL=/bin/bash
/usr/sbin/groupadd -r jgroups 2>/dev/null || :
/usr/sbin/useradd -c 'JBoss JGroups' -r -s $JGROUPS_SHELL -d /opt/jboss-jgroups -g jgroups jgroups 2>/dev/null || :

%files
%defattr(-,jgroups,jgroups)
/


