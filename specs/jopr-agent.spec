%define agent_name rhq-enterprise-agent
%define jopr_version 2.2.1

Summary:        JOPR Agent
Name:           jopr-agent
Version:        1.2.1
Release:        1
License:        LGPL
BuildArch:      noarch
Group:          Applications/System
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%define runuser jopr

%description
Jopr is an enterprise management solution for JBoss middleware projects and other application technologies. This pluggable project provides administration, monitoring, alerting, operational control and configuration in an enterprise setting with fine-grained security and an advanced extension model. This system is based on and plugin-compatible with the multi-vendor RHQ management project. It provides support for monitoring base operating system information on six operating systems as well as mangement of Apache, JBoss Application Server and other related projects. This package contains agent.

%install
install -d -m 755 $RPM_BUILD_ROOT/etc/sysconfig
touch $RPM_BUILD_ROOT/etc/sysconfig/jopr

%clean
rm -Rf $RPM_BUILD_ROOT

%files
%defattr(-,jopr,jopr)
/

%changelog
* Sat Jul 25 2009 Marek Goldmann 1.2.1
- Initial packaging
