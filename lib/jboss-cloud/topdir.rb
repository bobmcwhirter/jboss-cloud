require 'rake/tasklib'

module JBossCloud
  class Topdir < Rake::TaskLib

    def initialize(topdir)
      @topdir = topdir
      define
    end

    def define
      directory "#{@topdir}/SPECS"
      directory "#{@topdir}/SOURCES"
      directory "#{@topdir}/BUILD"
      directory "#{@topdir}/RPMS"
      directory "#{@topdir}/RPMS/noarch"
      #directory "#{@topdir}/RPMS/i386"
      directory "#{@topdir}/SRPMS"

      desc "Create the RPM build topdir"
      task "rpm:topdir" => [ 
        "#{@topdir}/SPECS",
        "#{@topdir}/SOURCES",
        "#{@topdir}/BUILD",
        "#{@topdir}/RPMS",
        "#{@topdir}/RPMS/noarch",
        #"#{@topdir}/RPMS/i386",
        "#{@topdir}/SRPMS",
      ]
    end
  end
end
