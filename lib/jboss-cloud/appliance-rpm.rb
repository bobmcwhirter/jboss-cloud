
module JBossCloud
  class ApplianceRPM < JBossCloud::RPM

    def initialize(topdir, spec_file, version, release)
      @topdir = topdir
      @spec_file = spec_file
      @version = version
      @release = release
      define
    end

    def define
      simple_name = File.basename( @spec_file, ".spec" )
      rpm_file = "#{@topdir}/RPMS/noarch/#{simple_name}-#{@version}-#{@release}.noarch.rpm"
      JBossCloud::RPM.provides[simple_name] = "#{simple_name}-#{@version}-#{@release}"

      desc "Build #{simple_name} RPM."
      task "rpm:#{simple_name}"=>[ rpm_file ]

      file rpm_file => [ @spec_file, "#{@topdir}/SOURCES/#{simple_name}-#{@version}.tar.gz", 'rpm:topdir' ] do
        root = `pwd`.strip
        Dir.chdir( File.dirname( @spec_file ) ) do
          exit_status=  execute_command "rpmbuild --define '_topdir #{@topdir}' --target noarch -ba #{simple_name}.spec"
          unless exit_status
            puts "\nBuilding #{simple_name} failed! Hint: consult above messages.\n\r"
            abort
          end
        end
      end

      file rpm_file=> [ 'rpm:dkms-open-vm-tools' ]
      file rpm_file=> [ 'rpm:vm2-support' ]
      file rpm_file=> [ 'rpm:oddthesis-repo' ]

    end
    
  end
end
