Summary: JBoss mod_cluster for Apache httpd
Name: httpd-mod_cluster
Version: 1.0.0.Beta2
Release: 1
License: LGPL
BuildRoot: %{_tmppath}/%{name}-buildroot
Group: Applications/System
BuildRequires: httpd-devel >= 2.2.10
Requires: httpd >= 2.2.10
Source0: http://labs.jboss.com/file-access/default/members/mod_cluster/freezone/dist/%{version}/mod_cluster-%{version}-src-ssl.tar.gz
Source1: mod_cluster.conf

%define __jar_repack %{nil}

%description
JBoss mod_cluster for Apache httpd

%prep
cd %{_topdir}/BUILD
rm -rf mod_cluster-%{version}-src-ssl
tar zxvf %{_topdir}/SOURCES/mod_cluster-%{version}-src-ssl.tar.gz mod_cluster-%{version}-src-ssl/srclib/mod_cluster/native

if [ $? -ne 0 ]; then
  exit $?
fi
cd mod_cluster-%{version}-src-ssl
chmod -R a+rX,g-w,o-w .

%install

%define httpd_dir /usr/lib/httpd
%define httpd_modules_dir /usr/lib/httpd/modules

%ifarch x86_64
	%define httpd_dir /usr/lib64/httpd
	%define httpd_modules_dir /usr/lib64/httpd/modules
%endif

cd mod_cluster-%{version}-src-ssl
cd srclib/mod_cluster/native/

modules=( mod_manager mod_proxy_cluster mod_slotmem )
allmodules=( advertise mod_manager mod_proxy_cluster mod_slotmem )

# mod_advertise
cd advertise
/bin/sh buildconf --enable-advertise
./configure --with-apache=%{httpd_dir}
make

cd ..

# rest of modules
for module in ${modules[@]} ; do
  pushd ${module}
  /bin/sh buildconf
  ./configure --with-apache=%{httpd_dir}
  make
  popd
done

install -d -m 755 $RPM_BUILD_ROOT%{httpd_modules_dir}
for module in ${allmodules[@]} ; do
  pushd ${module}
  cp *.so $RPM_BUILD_ROOT%{httpd_modules_dir}
  popd
done

install -d -m 755 $RPM_BUILD_ROOT/etc/httpd/conf.d
cp %{SOURCE1} $RPM_BUILD_ROOT/etc/httpd/conf.d/

%clean
rm -Rf $RPM_BUILD_ROOT

%pre

%files
%defattr(-,root,root)
/

%changelog
* Tue Dec 30 2008 Marek Goldmann 1.0.0.Beta2
- Added support for x86_64 arch

* Mon Dec 29 2008 Mob McWhirter 1.0.0.Beta2
- Initial packaging for Fedora 10 i386

