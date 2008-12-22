
Summary: JBoss mod_cluster for JBoss AS5
Name: as5-mod_cluster
Version: 1.0.0.Beta2
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Requires: jboss-as5
Source0: http://labs.jboss.com/file-access/default/members/mod_cluster/freezone/dist/%{version}/mod_cluster-%{version}-src-ssl.tar.gz
Patch: as5-mod_cluster-%{version}.patch
#BuildRoot: /tmp/%{name}

%define __jar_repack %{nil}

%description
JBoss mod_cluster for JBoss AS5

%prep
cd %{_topdir}/BUILD
rm -rf mod_cluster-%{version}-src-ssl
tar zxvf %{_topdir}/SOURCES/mod_cluster-%{version}-src-ssl.tar.gz mod_cluster-%{version}-src-ssl/srclib/mod_cluster
if [ $? -ne 0 ]; then
  exit $?
fi
cd mod_cluster-%{version}-src-ssl
chmod -R a+rX,g-w,o-w .

%patch -p1

%install

cd mod_cluster-%{version}-src-ssl
cd srclib/mod_cluster/
mvn package -Dmaven.test.skip=true

## every config but minimal
configs=( all  default  standard  web )

for config in ${configs[@]} ; do
  install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deployers
  cp -R ./target/mod-cluster.sar $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deployers/
done

%clean
#rm -Rf $RPM_BUILD_ROOT

%pre

%files
%defattr(-,root,root)
/


