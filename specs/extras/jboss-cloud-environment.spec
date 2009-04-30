%define maven_version 2.1.0

Summary:        JBoss-Cloud environment
Name:           jboss-cloud-environment
Version:        1.0.0.Beta3
Release:        1
License:        LGPL
BuildArch:      noarch
Group:          Applications/System
Source0:        http://www.apache.org/dist/maven/binaries/apache-maven-2.1.0-bin.tar.gz
Source1:        jboss-cloud-environment-sudo-oddthesis-user.patch
Source2:        http://rubyforge.org/frs/download.php/52301/net-ssh-2.0.11.gem
Source3:        http://rubyforge.org/frs/download.php/51130/net-sftp-2.0.2.gem
Source4:        http://rubyforge.org/frs/download.php/52464/xml-simple-1.0.12.gem
Source5:        http://rubyforge.org/frs/download.php/21724/builder-2.1.2.gem
Source6:        http://rubyforge.org/frs/download.php/52548/mime-types-1.16.gem
Source7:        http://rubyforge.org/frs/download.php/39375/aws-s3-0.5.1.gem
Source8:        http://rubyforge.org/frs/download.php/52588/amazon-ec2-0.3.6.gem
BuildRoot:      /tmp/%{name}
Requires:       shadow-utils
Requires:       git
Requires:       rubygems

%description
JBoss-Cloud environment. Required tools and source code for building appliances.

%prep
%setup -n apache-maven-%{maven_version}
/bin/rm -rf %{_topdir}/BUILD/jboss-cloud/sources

%install
/usr/bin/git clone git://github.com/bobmcwhirter/jboss-cloud.git $RPM_BUILD_ROOT/opt/jboss-cloud/sources
cd $RPM_BUILD_ROOT/opt/jboss-cloud/sources
/usr/bin/git submodule init
/usr/bin/git submodule update

mkdir -p $RPM_BUILD_ROOT/opt/jboss-cloud/tools/apache-maven-%{maven_version}
mkdir -p $RPM_BUILD_ROOT/opt/jboss-cloud/patches
mkdir -p $RPM_BUILD_ROOT/opt/jboss-cloud/tools/gems

cp -R %{_topdir}/BUILD/apache-maven-%{maven_version} $RPM_BUILD_ROOT/opt/jboss-cloud/tools/
cp %{SOURCE1} $RPM_BUILD_ROOT/opt/jboss-cloud/patches/
cp %{SOURCE2} $RPM_BUILD_ROOT/opt/jboss-cloud/tools/gems/
cp %{SOURCE3} $RPM_BUILD_ROOT/opt/jboss-cloud/tools/gems/
cp %{SOURCE4} $RPM_BUILD_ROOT/opt/jboss-cloud/tools/gems/
cp %{SOURCE5} $RPM_BUILD_ROOT/opt/jboss-cloud/tools/gems/
cp %{SOURCE6} $RPM_BUILD_ROOT/opt/jboss-cloud/tools/gems/
cp %{SOURCE7} $RPM_BUILD_ROOT/opt/jboss-cloud/tools/gems/
cp %{SOURCE8} $RPM_BUILD_ROOT/opt/jboss-cloud/tools/gems/

%clean
rm -Rf $RPM_BUILD_ROOT

%post

/usr/sbin/useradd -m -p '$1$rJT7v$rovvIw9nHJQdLZBvZJNPa0' oddthesis
/bin/chown oddthesis:oddthesis /opt/jboss-cloud -R

# install additional gems
/usr/bin/gem install -q /opt/jboss-cloud/tools/gems/net-ssh-2.0.11.gem
/usr/bin/gem install -q /opt/jboss-cloud/tools/gems/net-sftp-2.0.2.gem
/usr/bin/gem install -q /opt/jboss-cloud/tools/gems/xml-simple-1.0.12.gem
/usr/bin/gem install -q /opt/jboss-cloud/tools/gems/builder-2.1.2.gem
/usr/bin/gem install -q /opt/jboss-cloud/tools/gems/mime-types-1.16.gem
/usr/bin/gem install -q /opt/jboss-cloud/tools/gems/aws-s3-0.5.1.gem
/usr/bin/gem install -q /opt/jboss-cloud/tools/gems/amazon-ec2-0.3.6.gem

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
* Fri Apr 03 2009 Marek Goldmann 1.0.0.Beta3-1
- Maven version upgrade to 2.1.0

* Mon Mar 02 2009 Marek Goldmann 1.0.0.Beta3
- Maven version upgrade
