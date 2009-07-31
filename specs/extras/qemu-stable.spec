Summary:        QEMU is a FAST! processor emulator
Name:           qemu-stable
Version:        0.10
Release:        1%{?dist}
# Epoch because we pushed a qemu-1.0 package
Epoch:          2
License:        GPLv2+ and LGPLv2+ and BSD
Group:          Development/Tools
URL:            http://www.qemu.org/
Source:         http://repo.oddthesis.org/bundles/qemu-stable-23-07-2009.tar.gz

%description
QEMU is a generic and open source processor emulator which achieves a good
emulation speed by using dynamic translation. QEMU has two operating modes:

 * Full system emulation. In this mode, QEMU emulates a full system (for
   example a PC), including a processor and various peripherials. It can be
   used to launch different Operating Systems without rebooting the PC or
   to debug system code.
 * User mode emulation. In this mode, QEMU can launch Linux processes compiled
   for one CPU on another CPU.

As QEMU requires no host kernel patches to run, it is safe and easy to use.

%prep
%setup -n %{name}

./configure --target-list="i386-softmmu x86_64-softmmu" --prefix=/usr/qemu-stable

%build
make -j 4

%install
rm -rf $RPM_BUILD_ROOT

install -d -m 755 $RPM_BUILD_ROOT/usr/share/qemu-stable/bin/
cp x86_64-softmmu/qemu-system-x86_64 $RPM_BUILD_ROOT/usr/share/qemu-stable/bin/
cp i386-softmmu/qemu $RPM_BUILD_ROOT/usr/share/qemu-stable/bin/

install -d -m 755 $RPM_BUILD_ROOT/usr/share/qemu-stable/pc-bios/
cp -r pc-bios/* $RPM_BUILD_ROOT/usr/share/qemu-stable/pc-bios/

install -d -m 755 $RPM_BUILD_ROOT/usr/share/qemu-stable/bin/

%ifarch x86_64
echo -e '#!/bin/sh - \nexec /usr/share/qemu-stable/bin/qemu-system-x86_64 -L /usr/share/qemu-stable/pc-bios "$@"' > $RPM_BUILD_ROOT/usr/share/qemu-stable/bin/qemu.wrapper
%else
echo -e '#!/bin/sh - \nexec /usr/share/qemu-stable/bin/qemu -L /usr/share/qemu-stable/pc-bios "$@"' > $RPM_BUILD_ROOT/usr/share/qemu-stable/bin/qemu.wrapper
%endif

chmod +x $RPM_BUILD_ROOT/usr/share/qemu-stable/bin/qemu.wrapper

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
/

%changelog
* Wed Jul 22 2009 Marek Goldmann 0.10
- Initial packaging
