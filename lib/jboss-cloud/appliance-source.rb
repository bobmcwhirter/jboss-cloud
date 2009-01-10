require 'rake/tasklib'

module JBossCloud

  class ApplianceSource < Rake::TaskLib

    def initialize(build_dir, topdir, appliance_dir, version, release, arch)
      @build_dir        = build_dir
      @topdir           = topdir
      @appliance_dir    = appliance_dir
      @simple_name      = File.basename( appliance_dir )
      @super_simple_name      = File.basename( @simple_name, '-appliance' )
      @appliance_build_dir = "#{@build_dir}/appliances/#{arch}/#{@simple_name}"
      @version = version
      @release = release
      define
    end

    def define
      directory @appliance_build_dir

      source_files = FileList.new( "#{@appliance_dir}/*/**" )

      file "#{@topdir}/SOURCES/#{@simple_name}-#{@version}.tar.gz"=>[ @appliance_build_dir, source_files, 'rpm:topdir' ].flatten do
        stage_directory = "#{@appliance_build_dir}/sources/#{@simple_name}-#{@version}/appliances"
        FileUtils.rm_rf stage_directory
        FileUtils.mkdir_p stage_directory
        FileUtils.cp_r( "#{@appliance_dir}/", stage_directory  )
        Dir.chdir( "#{@appliance_build_dir}/sources" ) do
          execute_command( "tar zcvf #{@topdir}/SOURCES/#{@simple_name}-#{@version}.tar.gz #{@simple_name}-#{@version}/" )
        end
      end
 
      desc "Build source for #{@super_simple_name} appliance"
      task "appliance:#{@simple_name}:source" => [ "#{@topdir}/SOURCES/#{@simple_name}-#{@version}.tar.gz" ]
    end

  end
end
