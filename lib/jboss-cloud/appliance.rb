require 'rake/tasklib'

require 'jboss-cloud/appliance-source.rb'
require 'jboss-cloud/appliance-spec.rb'
require 'jboss-cloud/appliance-rpm.rb'
require 'jboss-cloud/appliance-kickstart.rb'
require 'jboss-cloud/appliance-image.rb'

module JBossCloud

  class Appliance < Rake::TaskLib

    def initialize( appliance_def )
      @build_dir        = Config.get.dir_build
      @topdir           = Config.get.dir_top
      @rpms_cache_dir   = Config.get.dir_rpms_cache
      @appliance_def    = appliance_def
      @appliance_name   = File.basename( appliance_def, '.appl' )
      @config           = build_config(@appliance_name)

      define
    end

    def build_config(name)
      config = ApplianceConfig.new
      
      config.name           = name
      config.arch           = ENV['ARCH'].nil? ? Config.get.build_arch : ENV['ARCH']
      config.disk_size      = ENV['DISK_SIZE'].nil? ? 2048 : ENV['DISK_SIZE'].to_i
      config.mem_size       = ENV['MEM_SIZE'].nil? ? 1024 : ENV['MEM_SIZE'].to_i
      config.network_name   = ENV['NETWORK_NAME'].nil? ? "NAT" : ENV['NETWORK_NAME']
      config.os_name        = ENV['OS_NAME'].nil? ? "fedora" : ENV['OS_NAME']
      config.os_version     = ENV['OS_VERSION'].nil? ? "10" : ENV['OS_VERSION']
      config.vcpu           = ENV['VCPU'].nil? ? 1 : ENV['VCPU'].to_i

      config
    end

    def define
      define_precursors
    end

    def define_precursors
      JBossCloud::ApplianceSource.new( @config, File.dirname( @appliance_def ) )
      JBossCloud::ApplianceSpec.new( @config, @appliance_name )
      JBossCloud::ApplianceRPM.new( "#{@build_dir}/appliances/#{@config.arch}/#{@appliance_name}/#{@appliance_name}.spec" )
      JBossCloud::ApplianceKickstart.new( @config, [ @appliance_name ] )
      JBossCloud::ApplianceImage.new( @config )
    end

  end
end
