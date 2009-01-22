#
# Convenience module for fetching files from a network source
#
# Copyright 2006-2007  Red Hat, Inc.
# Daniel P. Berrange <berrange@redhat.com>
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

import logging
import os
import stat
import subprocess
import urlgrabber.grabber as grabber
import urllib2
import urlparse
import ftplib
import tempfile
from virtinst import _virtinst as _

# This is a generic base class for fetching/extracting files from
# a media source, such as CD ISO, NFS server, or HTTP/FTP server
class ImageFetcher:

    def __init__(self, location, scratchdir):
        self.location = location
        self.scratchdir = scratchdir

    def saveTemp(self, fileobj, prefix):
        if not os.path.exists(self.scratchdir):
            os.makedirs(self.scratchdir, 0750)
        (fd, fn) = tempfile.mkstemp(prefix="virtinst-" + prefix, dir=self.scratchdir)
        block_size = 16384
        try:
            while 1:
                buff = fileobj.read(block_size)
                if not buff:
                    break
                os.write(fd, buff)
        finally:
            os.close(fd)
        return fn

    def prepareLocation(self):
        return True

    def cleanupLocation(self):
        pass

    def acquireFile(self, src, progresscb):
        raise NotImplementedError("Must be implemented in subclass")

    def hasFile(self, src):
        raise NotImplementedError("Must be implemented in subclass")

# Base class for downloading from FTP / HTTP
class URIImageFetcher(ImageFetcher):

    def _make_path(self, filename):
        path = self.location
        if not path.endswith("/"):
            path += "/"
        path += filename
        return path

    def hasFile(self, filename):
        raise NotImplementedError

    def prepareLocation(self):
        if not self.hasFile(""):
            raise ValueError(_("Opening URL %s failed.") % \
                              (self.location))

    def acquireFile(self, filename, progresscb):
        f = None
        try:
            path = self._make_path(filename)
            base = os.path.basename(filename)
            logging.debug("Fetching URI " + path)
            try:
                f = grabber.urlopen(path,
                                    progress_obj = progresscb,
                                    text = _("Retrieving file %s...") % base)
            except IOError, e:
                raise ValueError, _("Couldn't acquire file %s: %s") % \
                                    (path, str(e))
            tmpname = self.saveTemp(f, prefix=base + ".")
            logging.debug("Saved file to " + tmpname)
            return tmpname
        finally:
            if f:
                f.close()

class HTTPImageFetcher(URIImageFetcher):

    def hasFile(self, filename):
        try:
            path = self._make_path(filename)
            request = urllib2.Request(path)
            request.get_method = lambda: "HEAD"
            urllib2.urlopen(request)
        except Exception:
            logging.debug("HTTP hasFile: didn't find %s" % path)
            return False
        return True

class FTPImageFetcher(URIImageFetcher):

    def hasFile(self, filename):
        path = self._make_path(filename)

        url = urlparse.urlparse(path)
        try:
            ftp = ftplib.FTP(url[1])
            ftp.login()
            try:
                ftp.size(url[2])   # If a file
            except ftplib.all_errors:
                ftp.cwd(url[2])    # If a dir
        except ftplib.all_errors:
            logging.debug("FTP hasFile: couldn't access %s/%s" % \
                          (url[1], url[2]))
            return False
        return True

class LocalImageFetcher(ImageFetcher):

    def __init__(self, location, scratchdir, srcdir=None):
        ImageFetcher.__init__(self, location, scratchdir)
        self.srcdir = srcdir

    def acquireFile(self, filename, progresscb):
        f = None
        try:
            logging.debug("Acquiring file from " + self.srcdir + "/" + filename)
            base = os.path.basename(filename)
            try:
                src = self.srcdir + "/" + filename
                if stat.S_ISDIR(os.stat(src)[stat.ST_MODE]):
                    logging.debug("Found a directory")
                    return None
                else:
                    f = open(src, "r")
            except IOError, e:
                raise ValueError, _("Invalid file location given: ") + str(e)
            except OSError, (errno, msg):
                raise ValueError, \
                      _("Invalid file location given: %s: %s") % (errno, msg)
            tmpname = self.saveTemp(f, prefix=base + ".")
            logging.debug("Saved file to " + tmpname)
            return tmpname
        finally:
            if f:
                f.close()

    def hasFile(self, filename):
        if os.path.exists(os.path.abspath(self.srcdir + "/" + filename)):
            return True
        else:
            logging.debug("local hasFile: Couldn't find %s" % \
                          (self.srcdir + "/" + filename))
            return False

# This is a fetcher capable of extracting files from a NFS server
# or loopback mounted file, or local CDROM device
class MountedImageFetcher(LocalImageFetcher):

    def prepareLocation(self):
        cmd = None
        self.srcdir = tempfile.mkdtemp(prefix="virtinstmnt.", dir=self.scratchdir)
        mountcmd = "/bin/mount"
        if os.uname()[0] == "SunOS":
            mountcmd = "/usr/sbin/mount"

        logging.debug("Preparing mount at " + self.srcdir)
        if self.location.startswith("nfs:"):
            cmd = [mountcmd, "-o", "ro", self.location[4:], self.srcdir]
        else:
            if stat.S_ISBLK(os.stat(self.location)[stat.ST_MODE]):
                mountopt = "ro"
            else:
                mountopt = "ro,loop"
            if os.uname()[0] == 'SunOS':
                cmd = [mountcmd, "-F", "hsfs", "-o",
                        mountopt, self.location, self.srcdir]
            else:
                cmd = [mountcmd, "-o", mountopt, self.location, self.srcdir]
        ret = subprocess.call(cmd)
        if ret != 0:
            self.cleanupLocation()
            logging.debug("Mounting location %s failed" % (self.location,))
            raise ValueError(_("Mounting location %s failed") % (self.location))
        return True

    def cleanupLocation(self):
        logging.debug("Cleaning up mount at " + self.srcdir)
        if os.uname()[0] == "SunOS":
            cmd = ["/usr/sbin/umount", self.srcdir]
        else:
            cmd = ["/bin/umount", self.srcdir]
        subprocess.call(cmd)
        try:
            os.rmdir(self.srcdir)
        except:
            pass

class DirectImageFetcher(LocalImageFetcher):

    def prepareLocation(self):
        self.srcdir = self.location

