require 'rake/tasklib'

require 'jboss-cloud/appliance-source.rb'
require 'jboss-cloud/appliance-spec.rb'
require 'jboss-cloud/appliance-rpm.rb'
require 'jboss-cloud/appliance-kickstart.rb'

module JBossCloud

  class Appliance < Rake::TaskLib

    def initialize(build_dir, topdir, appliance_recipe, version, release)
      @build_dir        = build_dir
      @topdir           = topdir
      @appliance_recipe = appliance_recipe
      @version          = version
      @release          = release
      define
    end

    def define
      define_precursors
    end

    def define_precursors
      simple_name = File.basename( @appliance_recipe, ".pp" )
      JBossCloud::ApplianceSource.new( @build_dir, @topdir, File.dirname( @appliance_recipe ), @version, @release )
      JBossCloud::ApplianceSpec.new( @build_dir, @topdir, simple_name, @version, @release )
      JBossCloud::ApplianceRPM.new( @topdir, "#{@build_dir}/appliances/#{simple_name}/#{simple_name}.spec", @version, @release )
      JBossCloud::ApplianceKickstart.new( @build_dir, @topdir, simple_name, [ simple_name ] )
    end

  end
end
