
require 'rake/tasklib'
require 'jboss-cloud/appliance-vmx-image'

module JBossCloud
  class ApplianceImage < Rake::TaskLib

    def initialize(build_dir, rpms_cache_dir, kickstart_file, version, release)
      @build_dir = build_dir
      @rpms_cache_dir = rpms_cache_dir
      @kickstart_file = kickstart_file
      @version = version
      @release = release
      define
    end

    def define
     
      xml_file = File.dirname( @kickstart_file ) + "/" + File.basename( @kickstart_file, ".ks" ) + '.xml'
      simple_name = File.basename( @kickstart_file, ".ks" )
      super_simple_name = File.basename( simple_name, '-appliance' )

      desc "Build #{super_simple_name} appliance."
      task "appliance:#{simple_name}"=>[ xml_file ]

      file "#{@build_dir}/appliances/#{simple_name}/base-pkgs.ks" => [ "kickstarts/base-pkgs.ks" ] do
        FileUtils.cp( "kickstarts/base-pkgs.ks", "#{@build_dir}/appliances/#{simple_name}/base-pkgs.ks" )
      end

      tmp_dir = "#{Dir.pwd}/#{@build_dir}/tmp"
      directory tmp_dir

      file xml_file => [ @kickstart_file, "#{@build_dir}/appliances/#{simple_name}/base-pkgs.ks", tmp_dir ] do
        Rake::Task[ 'rpm:repodata:force' ].invoke
        execute_command( "sudo PYTHONUNBUFFERED=1 appliance-creator -d -v -t #{tmp_dir} --cache=#{@rpms_cache_dir} --config #{@kickstart_file} -o #{@build_dir}/appliances --name #{simple_name} --vmem 1024 --vcpu 1" )
      end

      ApplianceVMXImage.new( @build_dir, xml_file, @version, @release )

    end
  end
end
