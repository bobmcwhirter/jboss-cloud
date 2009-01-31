
Summary: JBoss mod_cluster for JBoss AS5 cloud profiles
Name: jboss-as5-cloud-mod_cluster
Version: 1.0.0.Beta3
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Requires: jboss-as5-cloud-profiles
Requires: patch
Source0: http://labs.jboss.com/file-access/default/members/mod_cluster/freezone/dist/%{version}/mod_cluster-%{version}-src-ssl.tar.gz
Source1: jboss-as5-mod_cluster-server-xml-group.patch
Source2: jboss-as5-mod_cluster-jboss-beans-xml-group.patch
Source3: jboss-as5-mod_cluster-server-xml-cluster.patch
Source4: jboss-as5-mod_cluster-jboss-beans-xml-cluster.patch
Patch: jboss-as5-mod_cluster-%{version}.patch
#BuildRoot: /tmp/%{name}

%define __jar_repack %{nil}

%description
JBoss mod_cluster for JBoss AS5 cloud profiles

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

configs=( cluster  group )

for config in ${configs[@]} ; do
  install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deploy
  cp -R ./target/mod-cluster.sar $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deploy/
done

install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/
cp %{SOURCE1} $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/
cp %{SOURCE2} $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/
cp %{SOURCE3} $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/
cp %{SOURCE4} $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/

%clean
#rm -Rf $RPM_BUILD_ROOT

%pre

%post
configs=( cluster  group )

for config in ${configs[@]} ; do
  pushd /opt/jboss-as5/server/${config}/deploy/jbossweb.sar/ > /dev/null
  /usr/bin/patch -s server.xml < /opt/jboss-as5/mod_cluster-patches/jboss-as5-mod_cluster-server-xml-${config}.patch
  pushd META-INF > /dev/null
  /usr/bin/patch -s jboss-beans.xml < /opt/jboss-as5/mod_cluster-patches/jboss-as5-mod_cluster-jboss-beans-xml-${config}.patch
  popd > /dev/null
  popd > /dev/null
done 

if [ `grep -c '^JBOSS_PROXY_LIST' /etc/jboss-as5.conf` -eq 0 ]; then
  echo "# Comma-separated list of address:port for mod_cluster front-end proxies"  >> /etc/jboss-as5.conf
  echo "JBOSS_PROXY_LIST=" >> /etc/jboss-as5.conf
fi

%preun
configs=( cluster  group )

for config in ${configs[@]} ; do
  pushd /opt/jboss-as5/server/${config}/deploy/jbossweb.sar/ > /dev/null
  /usr/bin/patch -sR server.xml < /opt/jboss-as5/mod_cluster-patches/jboss-as5-mod_cluster-server-xml-${config}.patch
  pushd META-INF > /dev/null
  /usr/bin/patch -sR jboss-beans.xml < /opt/jboss-as5/mod_cluster-patches/jboss-as5-mod_cluster-jboss-beans-xml-${config}.patch
  popd > /dev/null
  popd > /dev/null
done

mv /etc/jboss-as5.conf /etc/jboss-as5.conf.rpmsave
grep -v '^JBOSS_PROXY_LIST' /etc/jboss-as5.conf.rpmsave | grep -v '^# Comma-separated list of address:port for mod_cluster front-end proxies' > /etc/jboss-as5.conf

%files
%defattr(-,jboss,jboss)
/


