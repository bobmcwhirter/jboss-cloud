
require 'rake/tasklib'
require 'jboss-cloud/appliance-vmx-image'
require 'yaml'

module JBossCloud
  class ApplianceImage < Rake::TaskLib

    def initialize( config )
      @config           = config
      @build_dir        = Config.get.dir_build
      @rpms_cache_dir   = Config.get.dir_rpms_cache
      @version          = Config.get.version
      @release          = Config.get.release
      @kickstart_file   = "#{@build_dir}/appliances/#{@config.arch}/#{@config.name}/#{@config.name}.ks"
      define
    end

    def define

      xml_file = File.dirname( @kickstart_file ) + "/" + File.basename( @kickstart_file, ".ks" ) + '.xml'
      simple_name = File.basename( @kickstart_file, ".ks" )
      super_simple_name = File.basename( simple_name, '-appliance' )

      desc "Build #{super_simple_name} appliance."
      task "appliance:#{simple_name}"=>[ xml_file ]

      tmp_dir = "#{Dir.pwd}/#{@build_dir}/tmp"
      directory tmp_dir

      # here
      file xml_file => [ "appliance:#{simple_name}:kickstart", tmp_dir ] do
        Rake::Task[ 'rpm:repodata:force' ].invoke

        command = "sudo PYTHONUNBUFFERED=1 appliance-creator -d -v -t #{tmp_dir} --cache=#{@rpms_cache_dir}/#{@config.arch} --config #{@kickstart_file} -o #{@build_dir}/appliances/#{@config.arch} --name #{simple_name} --vmem #{@config.mem_size} --vcpu #{@config.vcpu}"

        execute_command( command )
      end

      ApplianceVMXImage.new( xml_file )

    end
  end
end
