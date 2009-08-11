Summary:        JBoss Cloud management support for appliances
Name:           jboss-cloud-management
Version:        1.0.0.Beta6
Release:        1
License:        LGPL
Requires:       git
Requires:       shadow-utils
Requires:       ruby
Requires:       rubygems
#Source0:        thin-ruby-env.patch
BuildRequires:  ruby
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Source0:        http://gems.rubyforge.org/gems/daemons-1.0.10.gem
Source1:        http://gems.rubyforge.org/gems/eventmachine-0.12.8.gem
Source2:        http://gems.rubyforge.org/gems/rack-1.0.0.gem
Source3:        http://gems.rubyforge.org/gems/thin-1.2.2.gem

%description
JBoss Cloud management support for appliances.

%install
rm -rf $RPM_BUILD_ROOT

/usr/bin/git clone git://github.com/goldmann/jboss-cloud-management.git $RPM_BUILD_ROOT/usr/share/%{name}

pushd $RPM_BUILD_ROOT/usr/share/%{name}
/usr/bin/git submodule init
/usr/bin/git submodule update

popd

install -d -m 755 $RPM_BUILD_ROOT/usr/share/%{name}-gems

cp %{SOURCE0} $RPM_BUILD_ROOT/usr/share/%{name}-gems
cp %{SOURCE1} $RPM_BUILD_ROOT/usr/share/%{name}-gems
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/%{name}-gems
cp %{SOURCE3} $RPM_BUILD_ROOT/usr/share/%{name}-gems

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

/usr/bin/gem install -ql /usr/share/%{name}-gems/*.gem

%files
%defattr(-,root,root)
/

%changelog
* Fri Jul 17 2009 Marek Goldmann 1.0.0.Beta6-1
- Added required gems

* Fri May 22 2009 Marek Goldmann 1.0.0.Beta3-1
- Submodules and building thin_parser

* Thu May 14 2009 Marek Goldmann 1.0.0.Beta2-1
- Added thin

* Sat May 09 2009 Marek Goldmann 1.0.0.Beta1-1
- Initial release
