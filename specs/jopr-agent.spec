%define agent_name rhq-enterprise-agent
%define jopr_version 2.3.0

Summary:        JOPR Agent
Name:           jopr-agent
Version:        1.3.0
Release:        1
License:        LGPL
BuildArch:      noarch
Source0:        jopr-agent.init
Source1:        jopr-agent-install.sh
Group:          Applications/System
Requires:       java-1.6.0-openjdk
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%define runuser jopr

%description
Jopr is an enterprise management solution for JBoss middleware projects and other application technologies. This pluggable project provides administration, monitoring, alerting, operational control and configuration in an enterprise setting with fine-grained security and an advanced extension model. This system is based on and plugin-compatible with the multi-vendor RHQ management project. It provides support for monitoring base operating system information on six operating systems as well as mangement of Apache, JBoss Application Server and other related projects. This package contains agent.

%install
install -d -m 755 $RPM_BUILD_ROOT/etc/sysconfig
touch $RPM_BUILD_ROOT/etc/sysconfig/%{name}

install -d -m 755 $RPM_BUILD_ROOT%{_initrddir}
install -m 755 %{SOURCE0} $RPM_BUILD_ROOT%{_initrddir}/%{name}

install -d -m 755 $RPM_BUILD_ROOT/usr/share/%{name}
install -m 755 %{SOURCE1} $RPM_BUILD_ROOT/usr/share/%{name}/jopr-agent-install.sh

%clean
rm -Rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/

%changelog
* Sat Jul 25 2009 Marek Goldmann 1.2.1
- Initial packaging
