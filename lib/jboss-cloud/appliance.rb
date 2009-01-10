require 'rake/tasklib'

require 'jboss-cloud/appliance-source.rb'
require 'jboss-cloud/appliance-spec.rb'
require 'jboss-cloud/appliance-rpm.rb'
require 'jboss-cloud/appliance-kickstart.rb'
require 'jboss-cloud/appliance-image.rb'

module JBossCloud

  class Appliance < Rake::TaskLib

    def initialize(build_dir, topdir, rpms_cache_dir, appliance_def, version, release, arch)
      @build_dir        = build_dir
      @topdir           = topdir
      @rpms_cache_dir   = rpms_cache_dir
      @appliance_def    = appliance_def
      @version          = version
      @release          = release
      @arch             = arch
      define
    end

    def define
      define_precursors
    end

    def define_precursors
      simple_name = File.basename( @appliance_def, ".appl" )
      JBossCloud::ApplianceSource.new( @build_dir, @topdir, File.dirname( @appliance_def ), @version, @release, @arch )
      JBossCloud::ApplianceSpec.new( @build_dir, @topdir, simple_name, @version, @release, @arch )
      JBossCloud::ApplianceRPM.new( @topdir, "#{@build_dir}/appliances/#{@arch}/#{simple_name}/#{simple_name}.spec", @version, @release )
      JBossCloud::ApplianceKickstart.new( @build_dir, @topdir, simple_name, @arch, [ simple_name ] )
      JBossCloud::ApplianceImage.new( @build_dir, @rpms_cache_dir, "#{@build_dir}/appliances/#{@arch}/#{simple_name}/#{simple_name}.ks", @version, @release, @arch )
    end

  end
end
