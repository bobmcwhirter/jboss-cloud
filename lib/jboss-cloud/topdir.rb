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
      directory "#{@topdir}/SRPMS"

      desc "Create the RPM build topdir"
      task "rpm:topdir" => [ 
        "#{@topdir}/SPECS",
        "#{@topdir}/SOURCES",
        "#{@topdir}/BUILD",
        "#{@topdir}/RPMS",
        "#{@topdir}/SRPMS",
      ]
    end
  end
end
