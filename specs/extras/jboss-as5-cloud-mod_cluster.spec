Summary: JBoss mod_cluster for JBoss AS5 cloud profiles
Name: jboss-as5-cloud-mod_cluster
Version: 1.0.0.CR2
Release: 1
License: LGPL
BuildArch: noarch
Group: Applications/System
Requires: jboss-as5-cloud-profiles
Requires: patch
Source0: http://labs.jboss.com/file-access/default/members/mod_cluster/freezone/dist/%{version}/mod-cluster-%{version}-bin.tar.gz
Source1: jboss-as5-mod_cluster-server-xml-group.patch
Source2: jboss-as5-mod_cluster-jboss-beans-xml-group.patch
Source3: jboss-as5-mod_cluster-server-xml-cluster.patch
Source4: jboss-as5-mod_cluster-jboss-beans-xml-cluster.patch
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

%define __jar_repack %{nil}

%description
JBoss mod_cluster for JBoss AS5 cloud profiles

%prep
%setup -T -b 0 -c -n %{name}

%install
rm -rf $RPM_BUILD_ROOT

configs=( cluster  group )

for config in ${configs[@]} ; do
  install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deploy
  cp -R mod-cluster.sar $RPM_BUILD_ROOT/opt/jboss-as5/server/${config}/deploy/
done

install -d -m 755 $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/
cp %{SOURCE1} $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/
cp %{SOURCE2} $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/
cp %{SOURCE3} $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/
cp %{SOURCE4} $RPM_BUILD_ROOT/opt/jboss-as5/mod_cluster-patches/

%clean
rm -rf $RPM_BUILD_ROOT

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


