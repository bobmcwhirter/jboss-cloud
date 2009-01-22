#
# Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
# Use is subject to license terms.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free  Software Foundation; either version 2 of the License, or
# (at your option)  any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301 USA.

import platform
import os

class User(object):
    """Defines a particular user account."""

    PRIV_CLONE = 1
    PRIV_NFS_MOUNT = 2
    PRIV_QEMU_SYSTEM = 3
    PRIV_CREATE_DOMAIN = 4
    PRIV_CREATE_NETWORK = 5

    _privs = [ PRIV_CLONE, PRIV_NFS_MOUNT, PRIV_QEMU_SYSTEM,
        PRIV_CREATE_DOMAIN, PRIV_CREATE_NETWORK ]

    def __init__(self, euid):
        self._euid = euid

    def has_priv(self, priv, conn=None):
        """Return if the given user is privileged enough to perform the
           given operation. This isn't entirely accurate currently,
           especially on Solaris."""

        if priv not in self._privs:
            raise ValueError('unknown privilege %s' % priv)

        if priv == self.PRIV_QEMU_SYSTEM:
            return self._euid == 0

        if platform.system() != 'SunOS':
            is_xen = not conn or conn.lower()[0:3] == 'xen'
            if priv in [ self.PRIV_CLONE, self.PRIV_CREATE_DOMAIN ]:
                if is_xen:
                    return self._euid == 0
                return True

            return self._euid == 0

        # Not easy to work out!
        if self._euid != User.current()._euid:
            return self._euid == 0

        import ucred
        cred = ucred.get(os.getpid())
        if priv in [ self.PRIV_CLONE, self.PRIV_CREATE_DOMAIN, self.PRIV_CREATE_NETWORK ]:
            return cred.has_priv('Effective', 'virt_manage')
        if priv == self.PRIV_NFS_MOUNT:
            return (cred.has_priv('Effective', 'sys_mount') and
                cred.has_priv('Effective', 'net_privaddr'))

    def current():
        """Return the current user."""
        return User(os.geteuid())

    current = staticmethod(current)
