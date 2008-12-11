
%define name    jboss-jgroups-appliance

%define aceHome /usr/share/ace

Summary: 	JBoss JGoups Appliance
Name:  		%{name}
Version: 	%{version}
Release: 	%{release}

Group:  	Applications/Internet
License: 	LGPLv2+
URL: 		http://oddthesis.org/
Source0: 	jboss-cloud-%{version}-%{release}.tar.gz
#BuildRoot: 	%{_tmppath}/%{name}-%{version}
BuildArch: 	noarch
Requires: 	ace-banners
Requires: 	ace-console
Requires: 	ace-ssh
Requires: 	java-1.6.0-openjdk-devel
Requires: 	jboss-jgroups
# The following are required to run within EC2
Requires: 	curl
Requires: 	rsync

%description
JBoss JGroups Appliance

%prep
#%setup -q
%setup -n jboss-cloud-%{version}


%build 

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{aceHome}
mkdir -p %{buildroot}/%{aceHome}/lenses
cp -R * %{buildroot}/%{aceHome}
#mv %{buildroot}/%{aceHome}/appliances/%{name}/lenses/* %{buildroot}/%{aceHome}/lenses

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%dir %{aceHome}
%{aceHome}/*

%changelog
* Thu Mar 26 2008 Bryan Kearney <bkearney@redhat.com> 0.0-1
- Initial packaging






















