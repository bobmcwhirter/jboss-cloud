require 'rake/tasklib'
require 'yaml'
require 'erb'

module JBossCloud

  class ApplianceKickstart < Rake::TaskLib

    def initialize( config, appliance_names=[] )
      @config            = config
      @build_dir         = Config.get.dir_build
      @topdir            = Config.get.dir_top
      @simple_name       = config.name
      @super_simple_name = File.basename( @simple_name, '-appliance' )
      @appliance_names   = appliance_names
      define
    end

    def define

      definition = { }
      #definition['local_repository_url'] = "file://#{@topdir}/RPMS/noarch"
      definition['disk_size']            = @config.disk_size

      # if we're building meta-appliance and disk size is less than 10GB
      if @simple_name == "meta-appliance" and @config.disk_size < 10240
        definition['disk_size'] = 10240
      end

      definition['post_script']          = ''
      definition['exclude_clause']       = ''
      definition['appliance_names']      = @appliance_names
      definition['arch']                 = @config.arch
      
      def definition.method_missing(sym,*args)
        self[ sym.to_s ]
      end

      definition['repos'] = [
        "repo --name=jboss-cloud --cost=10 --baseurl=file://#{@topdir}/RPMS/noarch",
        "repo --name=jboss-cloud-#{@config.arch} --cost=10 --baseurl=file://#{@topdir}/RPMS/#{@config.arch}",
      ]

      if ( File.exist?( "extra-rpms" ) )
        definition['repos'] << "repo --name=extra-rpms --cost=1 --baseurl=file://#{Dir.pwd}/extra-rpms/noarch"
      end

      for  appliance_name in @appliance_names
        if ( File.exist?( "appliances/#{appliance_name}/#{appliance_name}.post" ) )
          definition['post_script'] += "\n## #{appliance_name}.post\n"
          definition['post_script'] += File.read( "appliances/#{appliance_name}/#{appliance_name}.post" )
        end
      end

      all_excludes = []
      for  appliance_name in @appliance_names
        if ( File.exist?( "appliances/#{appliance_name}/#{appliance_name}.appl" ) )
          repo_lines, repo_excludes = read_repositories( "appliances/#{appliance_name}/#{appliance_name}.appl" )
          definition['repos'] += repo_lines
          all_excludes += repo_excludes
        end
      end

      unless ( all_excludes.empty? )
        definition['exclude_clause'] = "--excludepkgs=#{all_excludes.join(',')}"
      end

      directory "#{@build_dir}/appliances/#{@config.arch}/#{@simple_name}"

      file "#{@build_dir}/appliances/#{@config.arch}/#{@simple_name}/#{@simple_name}.ks"=>[ "#{@build_dir}/appliances/#{@config.arch}/#{@simple_name}" ] do
        template = File.dirname( __FILE__ ) + "/appliance.ks.erb"

        erb = ERB.new( File.read( template ) )
        File.open( "#{@build_dir}/appliances/#{@config.arch}/#{@simple_name}/#{@simple_name}.ks", 'w' ) {|f| f.write( erb.result( definition.send( :binding ) ) ) }
      end

      for appliance_name in @appliance_names
        file "#{@build_dir}/appliances/#{@config.arch}/#{@simple_name}/#{@simple_name}.ks"=>[ "rpm:#{appliance_name}" ]
      end

      desc "Build kickstart for #{@super_simple_name} appliance"
      task "appliance:#{@simple_name}:kickstart" => [ "#{@build_dir}/appliances/#{@config.arch}/#{@simple_name}/#{@simple_name}.ks" ]
    end

    def read_repositories(appliance_definition)

      defs = { }
      defs['arch'] = Config.get.build_arch
      defs['os_name'] = @config.os_name
      defs['os_version'] = @config.os_version

      def defs.method_missing(sym,*args)
        self[ sym.to_s ]
      end

      definition = YAML.load( ERB.new( File.read( appliance_definition ) ).result( defs.send( :binding ) ) )
      repos_def = definition['repos']
      repos = []
      excludes = []
      unless ( repos_def.nil? )
        repos_def.each do |name,config|
          repo_line = "repo --name=#{name} --baseurl=#{config['baseurl']}"
          unless ( config['filters'].nil? )
            excludes = config['filters']
          end
          repos << repo_line
        end
      end
      return [ repos, excludes ]
    end
  end

end

