
require 'rake'
require 'jboss-cloud/exec'
require 'jboss-cloud/topdir'
require 'jboss-cloud/repodata'
require 'jboss-cloud/rpm'
require 'jboss-cloud/appliance'

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

      @build_dir         = project_config[:build_dir]         || DEFAULT_PROJECT_CONFIG[:build_dir]
      @topdir            = project_config[:topdir]            || "#{self.build_dir}/topdir"
      @sources_cache_dir = project_config[:sources_cache_dir] || DEFAULT_PROJECT_CONFIG[:sources_cache_dir]
      @rpms_cache_dir    = project_config[:rpms_cache_dir]    || DEFAULT_PROJECT_CONFIG[:rpms_cache_dir]
    end

    def define_rules
      puts "defining rules"

      directory self.build_dir

      JBossCloud::Topdir.new( self.topdir )
      JBossCloud::Repodata.new( self.topdir, 'noarch' )

      Dir[ 'specs/extras/*.spec' ].each do |spec_file|
        JBossCloud::RPM.new( self.topdir, spec_file )
      end

      Dir[ "appliances/*/*.pp" ].each do |appliance_recipe|
        JBossCloud::Appliance.new( self.build_dir, "#{self.root}/#{self.topdir}", appliance_recipe, self.version, self.release )
      end

    end

  end
end
