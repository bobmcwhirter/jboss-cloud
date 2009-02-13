%define maven_version 2.0.9

Summary: JBoss Cloud environment
Name: jboss-cloud-environment
Version: 1
Release: dev
License: LGPL
BuildArch: noarch
Group: Applications/System
Source0: http://www.apache.org/dist/maven/binaries/apache-maven-2.0.9-bin.tar.gz
BuildRoot: /tmp/%{name}

%description
JBoss Cloud environment. Required tools and source code for building appliances.

%prep
%setup -n apache-maven-%{maven_version}
/bin/rm -rf %{_topdir}/BUILD/jboss-cloud/sources

%install
/usr/bin/git clone git://github.com/bobmcwhirter/jboss-cloud.git $RPM_BUILD_ROOT/opt/jboss-cloud/sources

mkdir -p $RPM_BUILD_ROOT/opt/jboss-cloud/tools/apache-maven-%{maven_version}

cp -R %{_topdir}/BUILD/apache-maven-%{maven_version} $RPM_BUILD_ROOT/opt/jboss-cloud/tools/

%clean
rm -Rf $RPM_BUILD_ROOT

%post
/bin/cp /etc/sudoers /etc/sudoers.orig
/bin/echo "oddthesis ALL = NOPASSWD: /usr/bin/appliance-creator" >> /etc/sudoers
/bin/echo "Defaults:oddthesis env_keep+=\"PYTHONUNBUFFERED\"" >> /etc/sudoers

/bin/echo "### JBoss Cloud Vars, do not modify this line! ###"  >> /home/oddthesis/.bashrc
/bin/echo "export PATH=$PATH:/opt/jboss-cloud/tools/apache-maven-%{maven_version}/bin" >> /home/oddthesis/.bashrc

%preun
/bin/rm /etc/sudoers
/bin/cp /etc/sudoers.orig /etc/sudoers

%files
%defattr(-,root,root)
/


