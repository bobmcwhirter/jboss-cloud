Summary:        JBoss Cloud management support for management appliance
Name:           jboss-cloud-management
Version:        1.0.0.Beta1
Release:        1
License:        LGPL
BuildArch:      noarch
Requires:       git
Requires:       shadow-utils
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
JBoss Cloud management support for management appliance.

%prep
/bin/rm -rf $RPM_BUILD_ROOT

%install
/usr/bin/git clone git://github.com/goldmann/jboss-cloud-management.git $RPM_BUILD_ROOT/usr/share/%{name}
/bin/rm -rf $RPM_BUILD_ROOT/usr/share/%{name}/.git
/bin/rm -rf $RPM_BUILD_ROOT/usr/share/%{name}/.gitignore

%clean
rm -rf $RPM_BUILD_ROOT

%pre
/usr/sbin/groupadd -r thin 2>/dev/null || :
/usr/sbin/useradd -r -g thin thin 2>/dev/null || :

%post
/bin/mkdir -p /var/log/jboss-cloud-management
/bin/chown thin:thin /var/log/jboss-cloud-management

%files
%defattr(-,root,root)
/

%changelog
* Sat May 09 2009 Marek Goldmann 1.0.0.Beta1-1
- Initial release
