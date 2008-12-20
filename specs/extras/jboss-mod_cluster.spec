
Summary: JBoss mod_cluster
Name: jboss-mod_cluster
Version: 1.0.0.Beta2
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: http://labs.jboss.com/file-access/default/members/mod_cluster/freezone/dist/%{version}/mod_cluster-%{version}-src-ssl.tar.gz
#BuildRoot: /tmp/%{name}

%define __jar_repack %{nil}

%description
JBoss mod_cluster for Apache

%prep
%setup -n mod_cluster-%{version}-src-ssl/

%install
 cd srclib/mod_cluster/native/
modules=( advertise mod_manager mod_proxy_cluster mod_slotmem )

for module in ${modules[@]} ; do
  pushd ${module}
  /bin/sh buildconf 
  ./configure --with-apache=/usr/lib/httpd
  make
  popd
  #cp -R ./jboss-rails.deployer $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deployers/
done

install -d -m 755 $RPM_BUILD_ROOT/usr/lib/httpd/modules/
for module in ${modules[@]} ; do
  pushd ${module}
  cp *.so $RPM_BUILD_ROOT/usr/lib/httpd/modules/
  popd
done

%clean
rm -Rf $RPM_BUILD_ROOT

%pre

%files
%defattr(-,jboss,jboss)
/


