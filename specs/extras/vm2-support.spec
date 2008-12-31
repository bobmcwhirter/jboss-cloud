
Summary: VM2 Support
Name: vm2-support
Version: 1.0.0.Beta1
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: vm2-support
BuildRoot: /tmp/%{name}

%define __jar_repack %{nil}

%description
VM2 Support

%prep
%setup -c -T

%install
install -d -m 755 $RPM_BUILD_ROOT/sbin
cp %{SOURCE0} $RPM_BUILD_ROOT/sbin/vm2-support


%clean
rm -Rf $RPM_BUILD_ROOT

%pre

%files
%defattr(-,root,root)
/


