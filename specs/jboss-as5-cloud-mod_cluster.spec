Summary:    JBoss mod_cluster for JBoss AS5 cloud profiles
Name:       jboss-as5-cloud-mod_cluster
Version:    1.0.2.GA
Release:    1
License:    LGPL
BuildArch:  noarch
Group:      Applications/System
Requires:   jboss-as5-cloud-profiles
Requires:   patch
Source0:    http://labs.jboss.com/file-access/default/members/mod_cluster/freezone/dist/%{version}/mod-cluster-%{version}-bin.tar.gz
Source1:    jboss-as-5.1.0.GA-mod_cluster.patch
BuildRoot:  %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

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

%clean
rm -rf $RPM_BUILD_ROOT

%pre

%post

cd /opt/jboss-as5/
patch -s -p1 < /opt/jboss-as5/mod_cluster-patches/jboss-as-5.1.0.GA-mod_cluster.patch

if [ `grep -c '^JBOSS_PROXY_LIST' /etc/jboss-as5.conf` -eq 0 ]; then
  echo "# Comma-separated list of address:port for mod_cluster front-end proxies"  >> /etc/jboss-as5.conf
  echo "JBOSS_PROXY_LIST=" >> /etc/jboss-as5.conf
fi

%preun

cd /opt/jboss-as5/
patch -sR -p1 < /opt/jboss-as5/mod_cluster-patches/jboss-as-5.1.0.GA-mod_cluster.patch

mv /etc/jboss-as5.conf /etc/jboss-as5.conf.rpmsave
grep -v '^JBOSS_PROXY_LIST' /etc/jboss-as5.conf.rpmsave | grep -v '^# Comma-separated list of address:port for mod_cluster front-end proxies' > /etc/jboss-as5.conf

%files
%defattr(-,jboss,jboss)
/

%changelog
* Sat May 30 2009 Marek Goldmann 1.0.0.GA
- Update to 1.0.0.GA