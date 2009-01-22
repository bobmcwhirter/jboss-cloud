#
# Utility functions used for guest installation
#
# Copyright 2006  Red Hat, Inc.
# Jeremy Katz <katzj@redhat.com>
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

#
# WARNING: the contents of this file, somewhat unfortunately, are legacy
# API. No incompatible changes are allowed to this file, and no new
# code should be added here (utility functions live in _util.py).
# Clients of virtinst shouldn't use these functions: if you think you
# need to, tell us why.
#

import platform
import random
import os.path
import re
import libxml2
import logging
import subprocess
from sys import stderr

import libvirt
from virtinst import _virtinst as _
import CapabilitiesParser
from User import User


KEYBOARD_DIR = "/etc/sysconfig/keyboard"
XORG_CONF = "/etc/X11/xorg.conf"

def default_route(nic = None):
    if platform.system() == 'SunOS':
        cmd = [ '/usr/bin/netstat', '-rn' ]
        if nic:
            cmd += [ '-I', nic ]
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)
        for line in proc.stdout.readlines():
            vals = line.split()
            if len(vals) > 1 and vals[0] == 'default':
                return vals[1]
        return None

    route_file = "/proc/net/route"
    d = file(route_file)

    defn = 0
    for line in d.xreadlines():
        info = line.split()
        if (len(info) != 11): # 11 = typical num of fields in the file
            print >> stderr, _("Invalid line length while parsing %s.") %(route_file)
            print >> stderr, _("Defaulting bridge to xenbr%d") % (defn)
            break
        try:
            route = int(info[1],16)
            if route == 0:
                return info[0]
        except ValueError:
            continue
    return None

def _default_nic():
    """Return the default NIC to use, if one is specified.
       This is NOT part of the API and may change at will."""

    dev = ''

    if platform.system() != 'SunOS':
        return dev

    # XXX: fails without PRIV_XVM_CONTROL
    proc = subprocess.Popen(['/usr/lib/xen/bin/xenstore-read',
        'device-misc/vif/default-nic'], stdout=subprocess.PIPE,
        stderr=subprocess.PIPE)
    out = proc.stdout.readlines()
    if len(out) > 0:
        dev = out[0].rstrip()

    return dev

def default_bridge():
    if platform.system() == 'SunOS':
        return _default_nic()

    rt = default_route()
    if rt is None:
        defn = None
    else:
        defn = int(rt[-1])

    if defn is None:
        return "xenbr0"
    else:
        return "xenbr%d"%(defn)

def default_network(conn):
    if platform.system() == 'SunOS':
        return ["bridge", _default_nic()]

    dev = default_route()

    if dev is not None and not is_uri_remote(conn.getURI()):
        # New style peth0 == phys dev, eth0 == bridge, eth0 == default route
        if os.path.exists("/sys/class/net/%s/bridge" % dev):
            return ["bridge", dev]

        # Old style, peth0 == phys dev, eth0 == netloop, xenbr0 == bridge,
        # vif0.0 == netloop enslaved, eth0 == default route
        defn = int(dev[-1])
        if os.path.exists("/sys/class/net/peth%d/brport" % defn) and \
           os.path.exists("/sys/class/net/xenbr%d/bridge" % defn):
            return ["bridge", "xenbr%d" % defn]

    return ["network", "default"]

def default_connection():
    if os.path.exists('/var/lib/xend'):
        if os.path.exists('/dev/xen/evtchn'):
            return 'xen' 
        if os.path.exists("/proc/xen"):
            return 'xen' 

    if os.path.exists("/usr/bin/qemu") or \
        os.path.exists("/usr/bin/qemu-kvm") or \
        os.path.exists("/usr/bin/kvm") or \
        os.path.exists("/usr/bin/xenner"):
        if User.current().has_priv(User.PRIV_QEMU_SYSTEM):
            return "qemu:///system"
        else:
            return "qemu:///session"
    return None

def get_cpu_flags():
    if platform.system() == 'SunOS':
        raise OSError('CPU flags not available')

    f = open("/proc/cpuinfo")
    lines = f.readlines()
    f.close()
    for line in lines:
        if not line.startswith("flags"):
            continue
        # get the actual flags
        flags = line[:-1].split(":", 1)[1]
        # and split them
        flst = flags.split(" ")
        return flst
    return []

def is_pae_capable(conn = None):
    """Determine if a machine is PAE capable or not."""
    if not conn:
        conn = libvirt.open('')
    return "pae" in conn.getCapabilities()

def is_hvm_capable():
    """Determine if a machine is HVM capable or not."""
    if platform.system() == 'SunOS':
        raise OSError('HVM capability not determinible')

    caps = ""
    if os.path.exists("/sys/hypervisor/properties/capabilities"):
        caps = open("/sys/hypervisor/properties/capabilities").read()
    if caps.find("hvm") != -1:
        return True
    return False

def is_kqemu_capable():
    return os.path.exists("/dev/kqemu")

def is_kvm_capable():
    return os.path.exists("/dev/kvm")

def is_blktap_capable():
    if platform.system() == 'SunOS':
        return False

    #return os.path.exists("/dev/xen/blktapctrl")
    f = open("/proc/modules")
    lines = f.readlines()
    f.close()
    for line in lines:
        if line.startswith("blktap ") or line.startswith("xenblktap "):
            return True
    return False

def get_default_arch():
    arch = os.uname()[4]
    if arch == "x86_64":
        return "x86_64"
    return "i686"

# this function is directly from xend/server/netif.py and is thus
# available under the LGPL,
# Copyright 2004, 2005 Mike Wray <mike.wray@hp.com>
# Copyright 2005 XenSource Ltd
def randomMAC(type = "xen"):
    """Generate a random MAC address.

    00-16-3E allocated to xensource
    54-52-00 used by qemu/kvm

    The OUI list is available at http://standards.ieee.org/regauth/oui/oui.txt.

    The remaining 3 fields are random, with the first bit of the first
    random field set 0.

    >>> randomMAC().startswith("00:16:36")
    True
    >>> randomMAC("foobar").startswith("00:16:36")
    True
    >>> randomMAC("xen").startswith("00:16:36")
    True
    >>> randomMAC("qemu").startswith("54:52:00")
    True

    @return: MAC address string
    """
    ouis = { 'xen': [ 0x00, 0x16, 0x36 ], 'qemu': [ 0x54, 0x52, 0x00 ] }

    try:
        oui = ouis[type]
    except KeyError:
        oui = ouis['xen']

    mac = oui + [
            random.randint(0x00, 0x7f),
            random.randint(0x00, 0xff),
            random.randint(0x00, 0xff) ]
    return ':'.join(map(lambda x: "%02x" % x, mac))

# the following three functions are from xend/uuid.py and are thus
# available under the LGPL,
# Copyright 2005 Mike Wray <mike.wray@hp.com>
# Copyright 2005 XenSource Ltd
def randomUUID():
    """Generate a random UUID."""

    return [ random.randint(0, 255) for dummy in range(0, 16) ]

def uuidToString(u):
    return "-".join(["%02x" * 4, "%02x" * 2, "%02x" * 2, "%02x" * 2,
                     "%02x" * 6]) % tuple(u)

def uuidFromString(s):
    s = s.replace('-', '')
    return [ int(s[i : i + 2], 16) for i in range(0, 32, 2) ]

# the following function quotes from python2.5/uuid.py
def get_host_network_devices():
    device = []
    for dirname in ['', '/sbin/', '/usr/sbin']:
        executable = os.path.join(dirname, "ifconfig")
        if not os.path.exists(executable):
            continue
        try:
            cmd = 'LC_ALL=C %s -a 2>/dev/null' % (executable)
            pipe = os.popen(cmd)
        except IOError:
            continue
        for line in pipe:
            if line.find("encap:Ethernet") > 0:
                words = line.lower().split()
                for i in range(len(words)):
                    if words[i] == "hwaddr":
                        device.append(words)
    return device

def get_max_vcpus(conn, type=None):
    """@conn libvirt connection to poll for max possible vcpus
       @type optional guest type (kvm, etc.)"""
    if type is None:
        type = conn.getType()
    try:
        m = conn.getMaxVcpus(type.lower())
    except libvirt.libvirtError:
        m = 32
    return m

def get_phy_cpus(conn):
    """Get number of physical CPUs."""
    hostinfo = conn.getInfo()
    pcpus = hostinfo[4] * hostinfo[5] * hostinfo[6] * hostinfo[7]
    return pcpus

def system(cmd):
    st = os.system(cmd)
    if os.WIFEXITED(st) and os.WEXITSTATUS(st) != 0:
        raise OSError("Failed to run %s, exited with %d" % 
                      (cmd, os.WEXITSTATUS(st)))

def xml_escape(str):
    """Replaces chars ' " < > & with xml safe counterparts"""
    str = str.replace("&", "&amp;")
    str = str.replace("'", "&apos;")
    str = str.replace("\"", "&quot;")
    str = str.replace("<", "&lt;")
    str = str.replace(">", "&gt;")
    return str
 
def compareMAC(p, q):
    """Compare two MAC addresses"""
    pa = p.split(":")
    qa = q.split(":")

    if len(pa) != len(qa):
        if p > q:
            return 1
        else:
            return -1

    for i in xrange(len(pa)):
        n = int(pa[i], 0x10) - int(qa[i], 0x10)
        if n > 0:
            return 1
        elif n < 0:
            return -1
    return 0

def _xorg_keymap():
    """Look in /etc/X11/xorg.conf for the host machine's keymap, and attempt to
       map it to a keymap supported by qemu"""

    kt = None
    try:
        f = open(XORG_CONF, "r")
    except IOError, e:
        logging.debug('Could not open "%s": %s ' % (XORG_CONF, str(e)))
    else:
        keymap_re = re.compile(r'\s*Option\s+"XkbLayout"\s+"(?P<kt>[a-z-]+)"')
        for line in f:
            m = keymap_re.match(line)
            if m:
                kt = m.group('kt')
                break
        else:
            logging.debug("Didn't find keymap in '%s'!" % XORG_CONF)
        f.close()
    return kt

def default_keymap():
    """Look in /etc/sysconfig for the host machine's keymap, and attempt to
       map it to a keymap supported by qemu"""

    # Set keymap to same as hosts
    import keytable
    keymap = "en-us"
    kt = None
    try:
        f = open(KEYBOARD_DIR, "r")
    except IOError, e:
        logging.debug('Could not open "/etc/sysconfig/keyboard" ' + str(e))
        kt = _xorg_keymap()
    else:
        while 1:
            s = f.readline()
            if s == "":
                break
            if re.search("KEYTABLE", s) != None or \
               (re.search("KEYBOARD", s) != None and
                re.search("KEYBOARDTYPE", s) == None):
                if s.count('"'):
                    delim = '"'
                elif s.count('='):
                    delim = '='
                else:
                    continue
                kt = s.split(delim)[1].strip()
        f.close()

    if kt and keytable.keytable.has_key(kt.lower()):
        keymap = keytable.keytable[kt]
    else:
        logging.debug("Didn't find keymap '%s' in keytable!" % kt)
    return keymap

def pygrub_path(conn=None):
    """
    Return the pygrub path for the current host, or connection if
    available.
    """
    # FIXME: This should be removed/deprecated when capabilities are
    #        fixed to provide bootloader info
    if conn:
        cap = CapabilitiesParser.parse(conn.getCapabilities())
        if (cap.host.arch == "i86pc"):
            return "/usr/lib/xen/bin/pygrub"
        else:
            return "/usr/bin/pygrub"

    if platform.system() == "SunOS":
        return "/usr/lib/xen/bin/pygrub"
    return "/usr/bin/pygrub"

def uri_split(uri):
    """
    Parse a libvirt hypervisor uri into it's individual parts
    @returns: tuple of the form (scheme (ex. 'qemu', 'xen+ssh'), username,
                                 hostname, path (ex. '/system'), query,
                                 fragment)
    """
    def splitnetloc(url, start=0):
        for c in '/?#': # the order is important!
            delim = url.find(c, start)
            if delim >= 0:
                break
        else:
            delim = len(url)
        return url[start:delim], url[delim:]

    username = netloc = query = fragment = ''
    i = uri.find(":")
    if i > 0:
        scheme, uri = uri[:i].lower(), uri[i+1:]
        if uri[:2] == '//':
            netloc, uri = splitnetloc(uri, 2)
            offset = netloc.find("@")
            if offset > 0:
                username = netloc[0:offset]
                netloc = netloc[offset+1:]
        if '#' in uri:
            uri, fragment = uri.split('#', 1)
        if '?' in uri:
            uri, query = uri.split('?', 1)
    else:
        scheme = uri.lower()
    return scheme, username, netloc, uri, query, fragment


def is_uri_remote(uri):
    try:
        split_uri = uri_split(uri)
        netloc = split_uri[2]

        if netloc == "":
            return False
        return True
    except Exception, e:
        logging.exception("Error parsing URI in is_remote: %s" % e)
        return True

def get_uri_hostname(uri):
    try:
        split_uri = uri_split(uri)
        netloc = split_uri[2]

        if netloc != "":
            return netloc
    except Exception, e:
        logging.warning("Cannot parse URI %s: %s" % (uri, str(e)))
    return "localhost"

def get_uri_transport(uri):
    try:
        split_uri = uri_split(uri)
        scheme = split_uri[0]
        username = split_uri[1]

        if scheme:
            offset = scheme.index("+")
            if offset > 0:
                return [scheme[offset+1:], username]
    except:
        pass
    return [None, None]

def get_uri_driver(uri):
    try:
        split_uri = uri_split(uri)
        scheme = split_uri[0]

        if scheme:
            offset = scheme.find("+")
            if offset > 0:
                return scheme[:offset]
            return scheme
    except Exception:
        pass
    return "xen"

def is_storage_capable(conn):
    """check if virConnectPtr passed has storage API support"""
    if not conn:
        return False
    if not isinstance(conn, libvirt.virConnect):
        raise ValueError(_("'conn' must be a virConnect instance."))
    try:
        if not dir(conn).count("listStoragePools"):
            return False
        conn.listStoragePools()
    except libvirt.libvirtError, e:
        if e.get_error_code() == libvirt.VIR_ERR_RPC or \
           e.get_error_code() == libvirt.VIR_ERR_NO_SUPPORT:
            return False
    return True

def get_xml_path(xml, path):
    """return the xpath from the passed xml"""
    doc = None
    ctx = None
    result = None
    try:
        doc = libxml2.parseDoc(xml)
        ctx = doc.xpathNewContext()
        ret = ctx.xpathEval(path)
        val = None
        if ret != None:
            if type(ret) == list:
                if len(ret) == 1:
                    val = ret[0].content
            else:
                val = ret
        result = val
    finally:
        if doc:
            doc.freeDoc()
        if ctx:
            ctx.xpathFreeContext()
    return result

def lookup_pool_by_path(conn, path):
    """
    Return the first pool with matching matching target path.
    return the first we find, active or inactive. This iterates over
    all pools and dumps their xml, so it is NOT quick.
    Favor running pools over inactive pools.
    @return virStoragePool object if found, None otherwise
    """
    if not is_storage_capable(conn):
        return None

    def check_pool(poolname, path):
        pool = conn.storagePoolLookupByName(poolname)
        xml_path = get_xml_path(pool.XMLDesc(0), "/pool/target/path")
        if os.path.abspath(xml_path) == path:
            return pool

    running_list = conn.listStoragePools()
    inactive_list = conn.listDefinedStoragePools()
    for plist in [running_list, inactive_list]:
        for name in plist:
            p = check_pool(name, path)
            if p:
                return p
    return None

def _test():
    import doctest
    doctest.testmod()
 
if __name__ == "__main__":
    _test()
