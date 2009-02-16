
require 'rake'
require 'jboss-cloud/exec'
require 'jboss-cloud/topdir'
require 'jboss-cloud/repodata'
require 'jboss-cloud/rpm'
require 'jboss-cloud/appliance'
require 'jboss-cloud/multi-appliance'
require 'ostruct'

module JBossCloud
  class Config
    @@config = nil

    def Config.get
      @@config
    end

    def initialize(name, version, release, arch, build_arch, dir_rpms_cache, dir_src_cache, dir_root, dir_top, dir_build, disk_size )
      @name = name
      @version = version
      @release = release
      @arch = arch
      @dir_rpms_cache = dir_rpms_cache
      @dir_src_cache = dir_src_cache
      @dir_root = dir_root
      @dir_top = dir_top
      @dir_build = dir_build

      @target = OpenStruct.new
      @target.os = OpenStruct.new

      @target.arch = build_arch
      @target.os.name = "fedora"
      @target.os.version = 10
      @target.disk_size = disk_size
      
      @@config = self
    end

    attr_reader :name
    attr_reader :version
    attr_reader :release
    attr_reader :target
    attr_reader :arch
    attr_reader :dir_rpms_cache
    attr_reader :dir_src_cache
    attr_reader :dir_root
    attr_reader :dir_top
    attr_reader :dir_build

    def version_with_release
      @version + (@release.empty? ? "" : "-" + @release)
    end
  end
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

      disk_size = ENV['DISK_SIZE'].nil? ? 2048 : ENV['DISK_SIZE'].to_i

      dir_build         = project_config[:build_dir]         || DEFAULT_PROJECT_CONFIG[:build_dir]
      dir_top           = project_config[:topdir]            || "#{dir_build}/topdir"
      dir_src_cache     = project_config[:sources_cache_dir] || DEFAULT_PROJECT_CONFIG[:sources_cache_dir]
      dir_rpms_cache    = project_config[:rpms_cache_dir]    || DEFAULT_PROJECT_CONFIG[:rpms_cache_dir]
     
      Config.new(name, version, release, arch, build_arch, dir_rpms_cache, dir_src_cache, dir_root, dir_top, dir_build, disk_size )
    end

    def define_rules

      if Config.get.arch == "i386" and Config.get.target.arch == "x86_64"
        puts "Building x86_64 images from i386 system isn't possible, aborting."
        abort
      end

      directory Config.get.dir_build

      puts "\n\rCurrent architecture:\t#{Config.get.arch}"

      JBossCloud::Topdir.new( Config.get.dir_top, [ 'noarch', 'i386', 'x86_64' ] )

      puts "Building architecture:\t#{Config.get.target.arch}\n\r"

      Dir[ 'specs/extras/*.spec' ].each do |spec_file|
        JBossCloud::RPM.new( Config.get.dir_top, spec_file, Config.get.target.arch )
      end

      Dir[ "appliances/*/*.appl" ].each do |appliance_def|
        JBossCloud::Appliance.new( Config.get.dir_build, "#{Config.get.dir_root}/#{Config.get.dir_top}", Config.get.dir_rpms_cache, appliance_def, Config.get.version, Config.get.release, Config.get.target.arch )
      end

      Dir[ "appliances/*.mappl" ].each do |multi_appliance_def|
        JBossCloud::MultiAppliance.new( Config.get.dir_build, "#{Config.get.dir_root}/#{Config.get.dir_top}", Config.get.dir_rpms_cache, multi_appliance_def, Config.get.version, Config.get.release, Config.get.target.arch )
      end
    end
  end
end
