
Summary: JBoss mod_cluster for JBoss AS5
Name: jboss-as5-mod_cluster
Version: 1.0.0.Beta2
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Requires: jboss-as5
Requires: patch
Source0: http://labs.jboss.com/file-access/default/members/mod_cluster/freezone/dist/%{version}/mod_cluster-%{version}-src-ssl.tar.gz
Source1: jboss-as5-mod_cluster-server-xml.patch
Source2: jboss-as5-mod_cluster-jboss-beans-xml.patch
Patch: jboss-as5-mod_cluster-%{version}.patch
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
  install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deploy
  cp -R ./target/mod-cluster.sar $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deploy/
done

install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/
cp %{SOURCE1} $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/
cp %{SOURCE2} $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/

%clean
#rm -Rf $RPM_BUILD_ROOT

%pre

%post
configs=( all  default  standard  web )

for config in ${configs[@]} ; do
  pushd /opt/jboss-as5/server/${config}/deploy/jbossweb.sar/
  /usr/bin/patch server.xml < /opt/jboss-as5/mod_cluster-patches/as5-mod_cluster-server-xml.patch
  pushd META-INF
  /usr/bin/patch jboss-beans.xml < /opt/jboss-as5/mod_cluster-patches/as5-mod_cluster-jboss-beans-xml.patch
  popd
  popd
done 

echo ""
echo "# Comma-separated list of address:port for mod_cluster front-end proxies"
echo "JBOSS_PROXY_LIST=" >> /etc/jboss-as5.conf

%preun
configs=( all  default  standard  web )

for config in ${configs[@]} ; do
  pushd /opt/jboss-as5/server/${config}/deploy/jbossweb.sar/
  /usr/bin/patch -R server.xml < /opt/jboss-as5/mod_cluster-patches/as5-mod_cluster-server-xml.patch
  pushd META-INF
  /usr/bin/patch -R jboss-beans.xml < /opt/jboss-as5/mod_cluster-patches/as5-mod_cluster-jboss-beans-xml.patch
  popd
  popd
done

%files
%defattr(-,root,root)
/


