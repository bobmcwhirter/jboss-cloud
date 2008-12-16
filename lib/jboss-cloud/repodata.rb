require 'rake/tasklib'

module JBossCloud
  class Repodata < Rake::TaskLib

    def initialize(topdir, arch)
      @topdir = topdir
      @arch = arch
      define
    end

    def define
      desc "Force a rebuild of the repository data"
      task "rpm:repodata:force"=>[ @topdir ] do
        execute_command( "createrepo #{@topdir}/RPMS/#{@arch}" )
      end

      desc "Build repository data"
      task 'rpm:repodata' => "#{@topdir}/RPMS/#{@arch}/repodata/repomd.xml"

      file "#{@topdir}/RPMS/#{@arch}/repodata/repomd.xml"=>FileList.new( "#{@topdir}/RPMS/#{@arch}/*.rpm" ) do
        execute_command( "createrepo #{@topdir}/RPMS/#{@arch}" )
      end
    end
  end
end
