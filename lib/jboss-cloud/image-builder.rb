
require 'rake'
require 'jboss-cloud/exec'
require 'jboss-cloud/topdir'
require 'jboss-cloud/repodata'
require 'jboss-cloud/rpm'
require 'jboss-cloud/appliance'
require 'jboss-cloud/multi-appliance'

module JBossCloud
  class ImageBuilder
    def self.setup(project_config)
      builder = JBossCloud::ImageBuilder.new( project_config )
      JBossCloud::ImageBuilder.config = builder
      builder.define_rules
      builder
    end

    def self.config
      @config
    end

    def self.config=(config)
      @config = config
    end

    DEFAULT_PROJECT_CONFIG = {
      :build_dir         =>'build',
      #:topdir            =>'build/topdir',
      :sources_cache_dir =>'sources-cache',
      :rpms_cache_dir    =>'rpms-cache',
    }

    attr_accessor :name
    attr_accessor :version
    attr_accessor :release
    attr_accessor :arch

    attr_accessor :root
    attr_accessor :build_dir
    attr_accessor :topdir
    attr_accessor :sources_cache_dir
    attr_accessor :rpms_cache_dir

    def initialize(project_config)
      @root = `pwd`.strip
      @name    = project_config[:name]
      @version = project_config[:version]
      @release = project_config[:release]
      @arch = (-1.size) == 8 ? "x86_64" : "i386"

      @build_dir         = project_config[:build_dir]         || DEFAULT_PROJECT_CONFIG[:build_dir]
      @topdir            = project_config[:topdir]            || "#{self.build_dir}/topdir"
      @sources_cache_dir = project_config[:sources_cache_dir] || DEFAULT_PROJECT_CONFIG[:sources_cache_dir]
      @rpms_cache_dir    = project_config[:rpms_cache_dir]    || DEFAULT_PROJECT_CONFIG[:rpms_cache_dir]
    end

    def define_rules
      directory self.build_dir

      build_arch = ENV['ARCH'].nil? ? self.arch : ENV['ARCH']

      puts "\n\rCurrent architecture:\t#{self.arch}"

      JBossCloud::Topdir.new( self.topdir, [ 'noarch', 'i386', 'x86_64' ] )

      puts "Building architecture:\t#{build_arch}\n\r"

      Dir[ 'specs/extras/*.spec' ].each do |spec_file|
        JBossCloud::RPM.new( self.topdir, spec_file, build_arch )
      end

      Dir[ "appliances/*/*.appl" ].each do |appliance_def|
        JBossCloud::Appliance.new( self.build_dir, "#{self.root}/#{self.topdir}", self.rpms_cache_dir, appliance_def, self.version, self.release, build_arch )
      end

      Dir[ "appliances/*.mappl" ].each do |multi_appliance_def|
        JBossCloud::MultiAppliance.new( self.build_dir, "#{self.root}/#{self.topdir}", self.rpms_cache_dir, multi_appliance_def, self.version, self.release, build_arch )
      end

    end

  end
end
