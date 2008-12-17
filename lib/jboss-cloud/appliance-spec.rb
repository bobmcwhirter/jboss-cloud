require 'rake/tasklib'
require 'yaml'
require 'erb'

module JBossCloud

  class ApplianceSpec < Rake::TaskLib

    def initialize(build_dir, topdir, simple_name, version, release)
      @build_dir        = build_dir
      @topdir           = topdir
      @simple_name      = simple_name
      @super_simple_name      = File.basename( simple_name, "-appliance" )
      @version = version
      @release = release
      define
    end

    def define
      definition = YAML.load_file( "appliances/#{@simple_name}/#{@simple_name}.appl" )
      definition['name']    = @simple_name
      definition['version'] = @version
      definition['release'] = @release
      def definition.method_missing(sym,*args)
        self[ sym.to_s ]
      end

      file "#{@build_dir}/appliances/#{@simple_name}/#{@simple_name}.spec"=>[ "#{@build_dir}/appliances/#{@simple_name}" ] do
        template = File.dirname( __FILE__ ) + "/appliance.spec.erb"

        erb = ERB.new( File.read( template ) )
        File.open( "#{@build_dir}/appliances/#{@simple_name}/#{@simple_name}.spec", 'w' ) {|f| f.write( erb.result( definition.send( :binding ) ) ) }
      end

      for p in definition['packages'] 
        if ( JBossCloud::RPM.provides.keys.include?( p ) )

          file "#{@topdir}/RPMS/noarch/#{@simple_name}-#{@version}-#{@release}.noarch.rpm"=>[ "rpm:#{p}" ] 
        end
      end
 
      desc "Build RPM spec for #{@super_simple_name} appliance"
      task "appliance:#{@simple_name}:spec" => [ "#{@build_dir}/appliances/#{@simple_name}/#{@simple_name}.spec" ]
    end

  end

end

