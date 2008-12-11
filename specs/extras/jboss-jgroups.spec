
Summary: JBoss JGroups
Name: jboss-jgroups
Version: %{version}
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: http://superb-east.dl.sourceforge.net/sourceforge/javagroups/JGroups-%{version}.bin.zip
BuildRoot: /tmp/%{name}

%define __jar_repack %{nil}

%description
JBoss JGroups

%prep
%setup -n JGroups-%{version}.bin

%install
mkdir -p $RPM_BUILD_ROOT/opt
cp -R . $RPM_BUILD_ROOT/opt/jboss-jgroups


#install -d -m 755 $RPM_BUILD_ROOT%{_initrddir}
#install -m 755 %{SOURCE1} $RPM_BUILD_ROOT%{_initrddir}/%{name}

#touch $RPM_BUILD_ROOT/etc/jboss-as5.conf

%clean
rm -Rf $RPM_BUILD_ROOT

%pre

%files
%defattr(-,jboss,jboss)
/


