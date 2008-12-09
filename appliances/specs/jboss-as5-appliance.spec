%define name    jboss-as5-appliance
%define version 1.0.0.Beta1
%define aceHome /usr/share/ace
%define pbuild %{_builddir}/%{name}-tmp

Summary: 	JBoss AS5 Appliance
Name:  		%{name}
Version: 	%{version}
Release: 	1%{?dist}

Group:  	Applications/Internet
License: 	LGPLv2+
URL: 		http://oddthesis.org/
Source0: 	%{name}-tmp.tar.gz
BuildRoot: 	%{_tmppath}/%{name}-%{version}
BuildArch: 	noarch
Requires: 	ace-banners
Requires: 	ace-console
Requires: 	ace-ssh
Requires: 	java-1.6.0-openjdk-devel
Requires: 	jboss-as5-appliance
# The following are required to run within EC2
Requires: 	curl
Requires: 	rsync

%description
JBoss AS5 Appliance

%prep
#%setup -q
%setup -n %{name}-tmp


%build 

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/%{aceHome}
mkdir -p %{buildroot}/%{aceHome}/lenses
cp -R %{pbuild}/* %{buildroot}/%{aceHome}
mv %{buildroot}/%{aceHome}/appliances/%{name}/lenses/* %{buildroot}/%{aceHome}/lenses

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%dir %{aceHome}
%{aceHome}/*

%changelog
* Thu Mar 26 2008 Bryan Kearney <bkearney@redhat.com> 0.0-1
- Initial packaging






















