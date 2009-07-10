Summary:        JBoss Cloud management support for appliances
Name:           jboss-cloud-management
Version:        1.0.0.Beta3
Release:        2
License:        LGPL
Requires:       git
Requires:       shadow-utils
Requires:       ruby
Requires:       rubygems
Source0:        thin-ruby-env.patch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%description
JBoss Cloud management support for appliances.

%prep
/bin/rm -rf $RPM_BUILD_ROOT

/usr/bin/git clone git://github.com/goldmann/jboss-cloud-management.git $RPM_BUILD_ROOT/usr/share/%{name}

pushd $RPM_BUILD_ROOT/usr/share/%{name}
/usr/bin/git submodule init
/usr/bin/git submodule update

pushd lib
patch -p0 < %{SOURCE0}
popd

popd

%build

pushd $RPM_BUILD_ROOT/usr/share/%{name}/lib/thin/ext/thin_parser
/usr/bin/ruby extconf.rb
/usr/bin/make
/bin/cp -f thin_parser.so ../../lib
/usr/bin/make clean
popd

%clean
rm -rf $RPM_BUILD_ROOT

%pre
#/bin/ln -s /usr/bin/ruby /usr/local/bin/ruby
/usr/sbin/groupadd -r thin 2>/dev/null || :
/usr/sbin/useradd -m -r -g thin thin 2>/dev/null || :

%post
/bin/mkdir -p /var/log/jboss-cloud-management
/bin/chown thin:thin /var/log/jboss-cloud-management
echo "sh /usr/share/%{name}/src/network-setup.sh" >> /etc/rc.local

%files
%defattr(-,root,root)
/

%changelog
* Fri May 22 2009 Marek Goldmann 1.0.0.Beta3-1
- Submodules and building thin_parser

* Thu May 14 2009 Marek Goldmann 1.0.0.Beta2-1
- Added thin

* Sat May 09 2009 Marek Goldmann 1.0.0.Beta1-1
- Initial release
