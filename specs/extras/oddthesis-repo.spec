%define is_fedora %(test -e /etc/fedora-release && echo 1 || echo 0)
%define is_redhat %(test -e /etc/redhat-release && echo 1 || echo 0)

%if %is_fedora
%define distro fedora
%else
%define distro rhel
%endif

Name:           oddthesis-repo
Version:        1.0
Release:        1
#%{?dist}
Summary:        Oddthesis Repository Configuration Files
Group:          System Environment/Base
License:        LGPL
URL:            http://oddthesis.org/
Source0:        RPM-GPG-KEY-oddthesis
Source1:        oddthesis.repo
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch:      noarch

%description
This package installs the 'RPM-GPG-KEY-oddthesis' file and the 'oddthesis.repo'
repository file.

%prep
%setup -c -T

%build

%install
rm -rf %{buildroot}

# gpg
install -Dpm 0644 %{SOURCE0} %{buildroot}%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-oddthesis

# yum
mkdir -p %{buildroot}%{_sysconfdir}/yum.repos.d/
cat %{SOURCE1} | sed "s/#distro#/%{distro}/g"  > %{buildroot}%{_sysconfdir}/yum.repos.d/oddthesis.repo

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{_sysconfdir}/pki/rpm-gpg/*
%config %{_sysconfdir}/yum.repos.d/*

%changelog
* Thu Jan 15 2009 Marek Goldmann <marek.goldmann@gmail.com> oddthesis-repo-1.0
- First spec file based upon Gregory R. Kriehn HOWTO
  (http://optics.csufresno.edu/~kriehn/fedora/fedora_files/f8/howto/yum-repository.html).
