%define jboss_cache_version 3.2.1.GA

Summary:        JBoss Application Server
Name:           jboss-as5
Version:        5.1.0.GA
Release:        2
License:        LGPL
BuildArch:      noarch
Group:          Applications/System
Source0:        http://internap.dl.sourceforge.net/sourceforge/jboss/jboss-%{version}-jdk6.zip
Source1:        jboss-as5.init
Source2:        http://downloads.sourceforge.net/project/jboss/JBossCache/JBossCache%20%{jboss_cache_version}/jbosscache-core-%{jboss_cache_version}-bin.zip
Requires:       shadow-utils
Requires:       coreutils
Requires:       java-1.6.0-openjdk
Requires:       initscripts
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%define runuser jboss
%define __jar_repack %{nil}

%description
The JBoss Application Server

%prep
%setup -n jboss-%{version}
%setup -T -b 2 -n jbosscache-core-%{jboss_cache_version}

%install

cd %{_topdir}/BUILD

install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5
cp -R jboss-%{version}/* $RPM_BUILD_ROOT/opt/jboss-as5
rm -Rf $RPM_BUILD_ROOT/opt/jboss-as5/server/*/deploy/ROOT.war

install -d -m 755 $RPM_BUILD_ROOT%{_initrddir}
install -m 755 %{SOURCE1} $RPM_BUILD_ROOT%{_initrddir}/%{name}

cp jbosscache-core-%{jboss_cache_version}/jbosscache-core.jar $RPM_BUILD_ROOT/opt/jboss-as5/server/all/lib/jbosscache-core.jar

touch $RPM_BUILD_ROOT/etc/jboss-as5.conf
echo 'JBOSS_GOSSIP_PORT=12001'    >> $RPM_BUILD_ROOT/etc/jboss-as5.conf
echo 'JBOSS_GOSSIP_REFRESH=5000'  >> $RPM_BUILD_ROOT/etc/jboss-as5.conf
#echo 'JBOSS_SERVER_PEER_ID='      >> $RPM_BUILD_ROOT/etc/jboss-as5.conf
#echo 'JBOSS_IP=0.0.0.0'           >> $RPM_BUILD_ROOT/etc/jboss-as5.conf
echo 'JAVA_HOME=/usr/lib/jvm/jre' >> $RPM_BUILD_ROOT/etc/jboss-as5.conf

%clean
rm -Rf $RPM_BUILD_ROOT

%pre
JBOSS_SHELL=/bin/bash
/usr/sbin/groupadd -r jboss 2>/dev/null || :
/usr/sbin/useradd -c JBossAS -r -s $JBOSS_SHELL -d /opt/jboss-as5 -g jboss jboss 2>/dev/null || :

%post
/bin/echo "echo JBOSS_SERVER_PEER_ID=\`ifconfig eth0 | awk '/inet addr/ {split (\$2,A,\":\"); print A[2]}' | awk -F\. '{ print ((\$1+\$2)*\$3*\$4)%255 }'\` >> /etc/jboss-as5.conf" >> /etc/rc.local
/bin/echo "echo JBOSS_IP=\`ifconfig eth0 | awk '/inet addr/ {split (\$2,A,\":\"); print A[2]}'\` >> /etc/jboss-as5.conf" >> /etc/rc.local

%files
%defattr(-,jboss,jboss)
/
#%attr(0755,root,root) %{_initrddir}/%{name}
#%attr(0755,root,root) /etc/jboss-as5.conf

%changelog
* Wed Aug 5 2009 Marek Goldmann 5.1.0.GA-2
- New defaults in /etc/jboss-as5.conf

* Mon May 25 2009 Marek Goldmann 5.1.0.GA-1
- JBoss AS version upgrade to 5.1.0.GA

* Tue Mar 03 2009 Marek Goldmann 5.0.1.GA-1
- JBoss AS version upgrade to 5.0.1.GA
