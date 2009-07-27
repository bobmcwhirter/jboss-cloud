Summary: JBoss Application Server 
Name: jboss-as5
Version: 5.1.0.GA
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: http://internap.dl.sourceforge.net/sourceforge/jboss/jboss-%{version}-jdk6.zip
Source1: jboss-as5.init
Requires: shadow-utils
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%define runuser jboss
%define __jar_repack %{nil}

%description
The JBoss Application Server

%prep
%setup -n jboss-%{version}

%install
mkdir -p $RPM_BUILD_ROOT/opt
cp -R . $RPM_BUILD_ROOT/opt/jboss-as5
rm -Rf $RPM_BUILD_ROOT/opt/jboss-as5/server/*/deploy/ROOT.war

install -d -m 755 $RPM_BUILD_ROOT%{_initrddir}
install -m 755 %{SOURCE1} $RPM_BUILD_ROOT%{_initrddir}/%{name}

touch $RPM_BUILD_ROOT/etc/jboss-as5.conf

echo 'JBOSS_GOSSIP_PORT=12001'      >> $RPM_BUILD_ROOT/etc/jboss-as5.conf
echo 'JBOSS_GOSSIP_REFRESH=5000'    >> $RPM_BUILD_ROOT/etc/jboss-as5.conf
#echo 'JBOSS_SERVER_PEER_ID='        >> $RPM_BUILD_ROOT/etc/jboss-as5.conf
echo 'JBOSS_IP=0.0.0.0'             >> $RPM_BUILD_ROOT/etc/jboss-as5.conf
echo 'JAVA_HOME=/usr/lib/jvm/java/' >> $RPM_BUILD_ROOT/etc/jboss-as5.conf

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

%changelog
* Mon May 25 2009 Marek Goldmann 5.1.0.GA-1
- JBoss AS version upgrade to 5.1.0.GA

* Tue Mar 03 2009 Marek Goldmann 5.0.1.GA-1
- JBoss AS version upgrade to 5.0.1.GA
