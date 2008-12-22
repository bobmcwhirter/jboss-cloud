
Summary: JBoss mod_cluster for Apache httpd
Name: httpd-mod_cluster
Version: 1.0.0.Beta2
Release: 1
License: LGPL
#BuildArch: i386
Group: Applications/System
Requires: httpd       >= 2.2.10
Requires: httpd-devel >= 2.2.10
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

cd mod_cluster-%{version}-src-ssl
cd srclib/mod_cluster/native/

modules=( advertise mod_manager mod_proxy_cluster mod_slotmem )

for module in ${modules[@]} ; do
  pushd ${module}
  /bin/sh buildconf 
  ./configure --with-apache=/usr/lib/httpd
  make
  popd
done

install -d -m 755 $RPM_BUILD_ROOT/usr/lib/httpd/modules/
for module in ${modules[@]} ; do
  pushd ${module}
  cp *.so $RPM_BUILD_ROOT/usr/lib/httpd/modules/
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


