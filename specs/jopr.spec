Summary:        JOPR
Name:           jopr
Version:        2.3.1
Release:        1
License:        LGPL
BuildArch:      noarch
Group:          Applications/System
Source0:        http://downloads.sourceforge.net/project/rhq/jopr/jopr-%{version}/jopr-server-%{version}.zip
Source1:        preconfigure-jopr-agent.sh
Source2:        agent-configuration.xml
Source3:        jopr.init
Source4:        preconfigure-jopr.sh
Source5:        rhq-server.properties
Requires:       shadow-utils
Requires:       java-1.6.0-openjdk
Requires:       unzip
Requires:       urw-fonts
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
AutoReqProv:    0
AutoReq:        0 

%define runuser jopr
%define __jar_repack %{nil}

%description
Jopr is an enterprise management solution for JBoss middleware projects and other application technologies. This pluggable project provides administration, monitoring, alerting, operational control and configuration in an enterprise setting with fine-grained security and an advanced extension model. This system is based on and plugin-compatible with the multi-vendor RHQ management project. It provides support for monitoring base operating system information on six operating systems as well as mangement of Apache, JBoss Application Server and other related projects.

%prep
%setup -n jopr-server-%{version}

%install
install -d -m 755 $RPM_BUILD_ROOT/opt/%{name}
cp -R . $RPM_BUILD_ROOT/opt/%{name}

install -d -m 755 $RPM_BUILD_ROOT/usr/share/%{name}
install -m 755 %{SOURCE1} $RPM_BUILD_ROOT/usr/share/%{name}/preconfigure-jopr-agent.sh
install -m 644 %{SOURCE2} $RPM_BUILD_ROOT/usr/share/%{name}/agent-configuration.xml
install -m 755 %{SOURCE4} $RPM_BUILD_ROOT/usr/share/%{name}/preconfigure-jopr.sh
install -m 644 %{SOURCE5} $RPM_BUILD_ROOT/usr/share/%{name}/rhq-server.properties

install -d -m 755 $RPM_BUILD_ROOT/etc/sysconfig
 
echo "JOPR_VERSION=%{version}"       > $RPM_BUILD_ROOT/etc/sysconfig/%{name}
echo "JOPR_HOME=/opt/jopr"          >> $RPM_BUILD_ROOT/etc/sysconfig/%{name}


install -d -m 755 $RPM_BUILD_ROOT%{_initrddir}
install -m 755 %{SOURCE3} $RPM_BUILD_ROOT%{_initrddir}/%{name}

%clean
rm -Rf $RPM_BUILD_ROOT

%pre
/usr/sbin/groupadd -r jopr 2>/dev/null || :
/usr/sbin/useradd -c "JOPR" -r -s /bin/bash -d /opt/jboss-jopr -g jopr jopr 2>/dev/null || :

%files
%defattr(-,jopr,jopr)
/

%changelog
* Thu Sep 24 2009 Marek Goldmann 2.3.1
- Upgrade to version 2.3.1

* Tue Sep 08 2009 Marek Goldmann 2.3.0
- Upgrade to Jopr 2.3.0

* Sat Jul 25 2009 Marek Goldmann 2.2.1
- Initial packaging
