
require 'rake'
require 'jboss-cloud/exec'
require 'jboss-cloud/topdir'
require 'jboss-cloud/repodata'
require 'jboss-cloud/rpm'
require 'jboss-cloud/appliance'
require 'jboss-cloud/multi-appliance'

module JBossCloud
  class Config
    def initialize(name, version, release, arch, build_arch, dir_rpms_cache, dir_src_cache, dir_root, dir_top, dir_build )
      @name = name
      @version = version
      @release = release
      @arch = arch
      @build_arch = build_arch
      @dir_rpms_cache = dir_rpms_cache
      @dir_src_cache = dir_src_cache
      @dir_root = dir_root
      @dir_top = dir_top
      @dir_build = dir_build
    end

    attr_reader :name
    attr_reader :version
    attr_reader :release
    attr_reader :arch
    attr_reader :build_arch
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
      dir_root    = `pwd`.strip
      name        = project_config[:name]
      version     = project_config[:version]
      release     = project_config[:release]
      arch        = (-1.size) == 8 ? "x86_64" : "i386"
      build_arch  = ENV['ARCH'].nil? ? arch : ENV['ARCH']

      dir_build         = project_config[:build_dir]         || DEFAULT_PROJECT_CONFIG[:build_dir]
      dir_top           = project_config[:topdir]            || "#{dir_build}/topdir"
      dir_src_cache     = project_config[:sources_cache_dir] || DEFAULT_PROJECT_CONFIG[:sources_cache_dir]
      dir_rpms_cache    = project_config[:rpms_cache_dir]    || DEFAULT_PROJECT_CONFIG[:rpms_cache_dir]

      @config = Config.new(name, version, release, arch, build_arch, dir_rpms_cache, dir_src_cache, dir_root, dir_top, dir_build )
    end

    def define_rules
      directory self.config.dir_build

      puts "\n\rCurrent architecture:\t#{self.config.arch}"

      JBossCloud::Topdir.new( self.config.dir_top, [ 'noarch', 'i386', 'x86_64' ] )

      puts "Building architecture:\t#{self.config.build_arch}\n\r"

      Dir[ 'specs/extras/*.spec' ].each do |spec_file|
        JBossCloud::RPM.new( self.config.dir_top, spec_file, self.config.build_arch )
      end

      Dir[ "appliances/*/*.appl" ].each do |appliance_def|
        JBossCloud::Appliance.new( self.config.dir_build, "#{self.config.dir_root}/#{self.config.dir_top}", self.config.dir_rpms_cache, appliance_def, self.config.version, self.config.release, self.config.build_arch )
      end

      Dir[ "appliances/*.mappl" ].each do |multi_appliance_def|
        JBossCloud::MultiAppliance.new( self.config.dir_build, "#{self.config.dir_root}/#{self.config.dir_top}", self.config.dir_rpms_cache, multi_appliance_def, self.config.version, self.config.release, self.config.build_arch )
      end
    end
  end
end
