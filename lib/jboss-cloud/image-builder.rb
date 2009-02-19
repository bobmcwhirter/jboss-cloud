
require 'rake'
require 'jboss-cloud/exec'
require 'jboss-cloud/topdir'
require 'jboss-cloud/repodata'
require 'jboss-cloud/rpm'
require 'jboss-cloud/appliance'
require 'jboss-cloud/multi-appliance'
require 'jboss-cloud/config'
require 'ostruct'

module JBossCloud
  class ImageBuilder
    def self.setup(project_config)
      builder = JBossCloud::ImageBuilder.new( project_config )
      JBossCloud::ImageBuilder.builder = builder
      builder.define_rules
      builder
    end

    def self.builder
      @builder
    end

    def self.builder=(builder)
      @builder = builder
    end

    def config
      @config
    end

    DEFAULT_PROJECT_CONFIG = {
      :build_dir         =>'build',
      #:topdir            =>'build/topdir',
      :sources_cache_dir =>'sources-cache',
      :rpms_cache_dir    =>'rpms-cache',
    }

    def initialize(project_config)
      valid_archs = [ "i386", "x86_64" ]

      dir_root    = `pwd`.strip
      name        = project_config[:name]
      version     = project_config[:version]
      release     = project_config[:release]
      arch        = (-1.size) == 8 ? "x86_64" : "i386"

      if (!ENV['ARCH'].nil? and !valid_archs.include?( ENV['ARCH']))
        puts "'#{ENV['ARCH']}' is not a valid build architecture. Available architectures: #{valid_archs.join(", ")}, aborting."
        abort
      end

      build_arch = ENV['ARCH'].nil? ? arch : ENV['ARCH']

      if (!ENV['DISK_SIZE'].nil? && (ENV['DISK_SIZE'].to_i == 0 || ENV['DISK_SIZE'].to_i % 1024 > 0))
        puts "'#{ENV['DISK_SIZE']}' is not a valid disk size. Please enter valid size in MB, aborting."
        abort
      end

      dir_build         = project_config[:build_dir]         || DEFAULT_PROJECT_CONFIG[:build_dir]
      dir_top           = project_config[:topdir]            || "#{dir_build}/topdir"
      dir_src_cache     = project_config[:sources_cache_dir] || DEFAULT_PROJECT_CONFIG[:sources_cache_dir]
      dir_rpms_cache    = project_config[:rpms_cache_dir]    || DEFAULT_PROJECT_CONFIG[:rpms_cache_dir]
     
      Config.new.init(name, version, release, arch, build_arch, dir_rpms_cache, dir_src_cache, dir_root, dir_top, dir_build)
    end
    
    def define_rules

      if Config.get.arch == "i386" and Config.get.build_arch == "x86_64"
        puts "Building x86_64 images from i386 system isn't possible, aborting."
        abort
      end

      directory Config.get.dir_build

      puts "\n\rCurrent architecture:\t#{Config.get.arch}"

      JBossCloud::Topdir.new( [ 'noarch', 'i386', 'x86_64' ] )

      puts "Building architecture:\t#{Config.get.build_arch}\n\r"

      Dir[ 'specs/extras/*.spec' ].each do |spec_file|
        JBossCloud::RPM.new( spec_file )
      end

      Dir[ "appliances/*/*.appl" ].each do |appliance_def|
        JBossCloud::Appliance.new( appliance_def )
      end

      Dir[ "appliances/*.mappl" ].each do |multi_appliance_def|
        JBossCloud::MultiAppliance.new( Config.get.dir_build, "#{Config.get.dir_root}/#{Config.get.dir_top}", Config.get.dir_rpms_cache, multi_appliance_def, Config.get.version, Config.get.release, Config.get.build_arch )
      end
    end
  end
end
