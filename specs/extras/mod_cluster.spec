Summary: JBoss mod_cluster for Apache httpd
Name: mod_cluster
Version: 1.0.0.CR1
Release: 1
License: LGPL
BuildRoot: %{_tmppath}/%{name}-buildroot
Group: Applications/System
BuildRequires: httpd-devel >= 2.2.8
Requires: httpd-devel >= 2.2.8
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

%define apxs_file /usr/sbin/apxs
%define httpd_modules_dir /usr/lib/httpd/modules

%ifarch x86_64
	%define httpd_modules_dir /usr/lib64/httpd/modules
%endif

cd mod_cluster-%{version}-src-ssl
cd srclib/mod_cluster/native/

modules=( mod_manager mod_proxy_cluster mod_slotmem )
allmodules=( advertise mod_manager mod_proxy_cluster mod_slotmem )

# mod_advertise
cd advertise
/bin/sh buildconf --enable-advertise
./configure --with-apxs=%{apxs_file}
make

cd ..

# rest of modules
for module in ${modules[@]} ; do
  pushd ${module}
  /bin/sh buildconf
  ./configure --with-apxs=%{apxs_file}
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

%post

pushd /etc/httpd/conf > /dev/null

cp httpd.conf httpd.conf.orig
sed s/"^LoadModule proxy_balancer_module"/"#LoadModule proxy_balancer_module"/ httpd.conf.orig > httpd.conf

popd > /dev/null

%preun

pushd /etc/httpd/conf > /dev/null

rm -f httpd.conf.orig > /dev/null
cp httpd.conf httpd.conf.orig
sed s/"^#LoadModule proxy_balancer_module"/"LoadModule proxy_balancer_module"/ httpd.conf.orig > httpd.conf

popd > /dev/null

%files
%defattr(-,root,root)
/

%changelog
* Thu Mar 26 2009 Marek Goldmann 1.0.0.CR1
- Update to 1.0.0.CR1

* Fri Feb 20 2009 Marek Goldmann 1.0.0.Beta4
- Update to 1.0.0.Beta4

* Wed Feb 04 2009 Marek Goldmann 1.0.0.Beta3
- Commenting proxy_balancer_module

* Tue Dec 30 2008 Marek Goldmann 1.0.0.Beta2
- Added support for x86_64 arch

* Mon Dec 29 2008 Mob McWhirter 1.0.0.Beta2
- Initial packaging for Fedora 10 i386

