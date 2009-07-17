%define maven_version 2.1.0

Summary:        JBoss Cloud environment
Name:           jboss-cloud-environment
Version:        1.0.0.Beta4
Release:        1
License:        LGPL
BuildArch:      noarch
Group:          Applications/System
Source0:        http://www.apache.org/dist/maven/binaries/apache-maven-2.1.0-bin.tar.gz
Source1:        jboss-cloud-environment-sudo-oddthesis-user.patch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires:       shadow-utils
Requires:       git

%description
JBoss Cloud environment. Required tools and source code for building appliances.

%prep
%setup -n apache-maven-%{maven_version}
/bin/rm -rf %{_topdir}/BUILD/jboss-cloud/sources

%install
/usr/bin/git clone git://github.com/bobmcwhirter/jboss-cloud.git $RPM_BUILD_ROOT/opt/jboss-cloud/sources
cd $RPM_BUILD_ROOT/opt/jboss-cloud/sources
/usr/bin/git submodule init
/usr/bin/git submodule update

cd lib/jboss-appliance-support
/usr/bin/git submodule init
/usr/bin/git submodule update

mkdir -p $RPM_BUILD_ROOT/opt/jboss-cloud/tools/apache-maven-%{maven_version}
mkdir -p $RPM_BUILD_ROOT/opt/jboss-cloud/patches

cp -R %{_topdir}/BUILD/apache-maven-%{maven_version} $RPM_BUILD_ROOT/opt/jboss-cloud/tools/
cp %{SOURCE1} $RPM_BUILD_ROOT/opt/jboss-cloud/patches/

%clean
rm -Rf $RPM_BUILD_ROOT

%post

/usr/sbin/useradd -m -p '$1$rJT7v$rovvIw9nHJQdLZBvZJNPa0' oddthesis
/bin/chown oddthesis:oddthesis /opt/jboss-cloud -R

patch -s /etc/sudoers < /opt/jboss-cloud/patches/jboss-cloud-environment-sudo-oddthesis-user.patch

/bin/echo "### JBoss Cloud Vars, do not modify this line! ###" >> /home/oddthesis/.bashrc
/bin/echo "export PATH=$PATH:/opt/jboss-cloud/tools/apache-maven-%{maven_version}/bin:/usr/local/bin" >> /home/oddthesis/.bashrc
/bin/echo "export JAVA_HOME=/usr/lib/jvm/java-openjdk" >> /home/oddthesis/.bashrc

%preun

#patch -sR /etc/sudoers < /opt/jboss-cloud/patches/jboss-cloud-environment-sudo-oddthesis-user.patch

%files
%defattr(-,root,root)
/

%changelog
* Wed May 13 2009 Marek Goldmann 1.0.0.Beta4-1
- Removed hardcoded gems

* Fri Apr 03 2009 Marek Goldmann 1.0.0.Beta3-1
- Maven version upgrade to 2.1.0

* Mon Mar 02 2009 Marek Goldmann 1.0.0.Beta3
- Maven version upgrade
