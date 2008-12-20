require 'rake/tasklib'

module JBossCloud
  class Topdir < Rake::TaskLib

    def initialize(topdir, arches)
      @topdir = topdir
      @arches = arches
      define
    end

    def define
      directory "#{@topdir}/SPECS"
      directory "#{@topdir}/SOURCES"
      directory "#{@topdir}/BUILD"
      directory "#{@topdir}/RPMS"
      for arch in @arches 
        directory "#{@topdir}/RPMS/#{arch}"
      end
      directory "#{@topdir}/SRPMS"

      desc "Create the RPM build topdir"
      task "rpm:topdir" => [ 
        "#{@topdir}/SPECS",
        "#{@topdir}/SOURCES",
        "#{@topdir}/BUILD",
        "#{@topdir}/RPMS",
        "#{@topdir}/SRPMS",
      ]
      for arch in @arches
        task "rpm:topdir" => [ "#{@topdir}/RPMS/#{arch}" ]
      end

      JBossCloud::Repodata.new( @topdir, @arches )
    end
  end
end
