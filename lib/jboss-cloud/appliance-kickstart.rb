require 'rake/tasklib'
require 'yaml'
require 'erb'

module JBossCloud

  class ApplianceKickstart < Rake::TaskLib

    def initialize(build_dir, topdir, appliance_name, simple_names=[])
      @build_dir        = build_dir
      @topdir           = topdir
      @appliance_name   = appliance_name
      @simple_names     = simple_names
      define
    end

    def define
      definition = { }
      definition['local_repository_url'] = "#{@topdir}/RPMS/noarch"
      definition['post_script']          = ''
      definition['appliance_names']      = @simple_names
      def definition.method_missing(sym,*args)
        self[ sym.to_s ]
      end

     
      file "#{@build_dir}/appliances/#{@appliance_name}/#{@appliance_name}.ks"=>[ "#{@build_dir}/appliances/#{@appliance_name}" ] do
        template = File.dirname( __FILE__ ) + "/appliance.ks.erb"
        puts "using template #{template}"

        erb = ERB.new( File.read( template ) )
        File.open( "#{@build_dir}/appliances/#{@appliance_name}/#{@appliance_name}.ks", 'w' ) {|f| f.write( erb.result( definition.send( :binding ) ) ) }
      end

      for simple_name in @simple_names
        file "#{@build_dir}/appliances/#{@appliance_name}/#{@appliance_name}.ks"=>[ "rpm:#{simple_name}" ] 
      end

      desc "Build kickstart for #{@appliance_name} appliance"
      task "appliance:#{@appliance_name}:kickstart" => [ "#{@build_dir}/appliances/#{@appliance_name}/#{@appliance_name}.ks" ]
    end

  end

end

