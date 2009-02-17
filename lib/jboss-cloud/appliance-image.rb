
require 'rake/tasklib'
require 'jboss-cloud/appliance-vmx-image'
require 'yaml'

module JBossCloud
  class ApplianceImage < Rake::TaskLib

    def initialize(build_dir, rpms_cache_dir, kickstart_file, version, release, arch)
      @build_dir = build_dir
      @rpms_cache_dir = rpms_cache_dir
      @kickstart_file = kickstart_file
      @version = version
      @release = release
      @arch = arch
      define
    end

    def define

      xml_file = File.dirname( @kickstart_file ) + "/" + File.basename( @kickstart_file, ".ks" ) + '.xml'
      simple_name = File.basename( @kickstart_file, ".ks" )
      super_simple_name = File.basename( simple_name, '-appliance' )

      desc "Build #{super_simple_name} appliance."
      task "appliance:#{simple_name}"=>[ xml_file ] do
        File.open("#{@build_dir}/appliances/#{@arch}/#{simple_name}/config.yaml","w+").puts( Config.get.target.to_yaml )
      end

      file "#{@build_dir}/appliances/#{@arch}/#{simple_name}/base-pkgs.ks" => [ "kickstarts/base-pkgs.ks" ] do
        FileUtils.cp( "kickstarts/base-pkgs.ks", "#{@build_dir}/appliances/#{@arch}/#{simple_name}/base-pkgs.ks" )
      end

      tmp_dir = "#{Dir.pwd}/#{@build_dir}/tmp"
      directory tmp_dir

      file xml_file => [ @kickstart_file, "#{@build_dir}/appliances/#{@arch}/#{simple_name}/base-pkgs.ks", tmp_dir ] do
        Rake::Task[ 'rpm:repodata:force' ].invoke
        #execute_command( "sudo PYTHONUNBUFFERED=1 appliance-creator -d -v -t #{tmp_dir} --cache=#{@rpms_cache_dir}/#{@arch} --config #{@kickstart_file} -o #{@build_dir}/appliances/#{@arch} --name #{simple_name} --vmem #{Config.get.target.mem_size} --vcpu #{Config.get.target.vcpu}" )
      end

      ApplianceVMXImage.new( xml_file )

    end
  end
end
