require 'rake/tasklib'
require 'yaml'
require 'erb'

module JBossCloud

  class ApplianceKickstart < Rake::TaskLib

    def initialize(build_dir, topdir, simple_name, appliance_names=[])
      @build_dir         = build_dir
      @topdir            = topdir
      @simple_name       = simple_name
      @super_simple_name = File.basename( @simple_name, '-appliance' )
      @appliance_names   = appliance_names
      define
    end

    def define
      definition = { }
      #definition['local_repository_url'] = "file://#{@topdir}/RPMS/noarch"
      definition['post_script']          = ''
      definition['exclude_clause']       = ''
      definition['appliance_names']      = @appliance_names
      def definition.method_missing(sym,*args)
        self[ sym.to_s ]
      end
      definition['repos'] = [
        "repo --name=jboss-cloud --cost=10 --baseurl=file://#{@topdir}/RPMS/noarch",
        # "repo --name=jboss-cloud-i386   --cost=10 --baseurl=file://#{@topdir}/RPMS/i386",
      ]
      if ( File.exist?( "appliances/#{@simple_name}/#{@simple_name}.post" ) )
        definition['post_script'] = File.read( "appliances/#{@simple_name}/#{@simple_name}.post" )
      end

      all_excludes = []
      for  appliance_name in @appliance_names
        if ( File.exist?( "appliances/#{appliance_name}/#{appliance_name}.appl" ) )
          repo_lines, repo_excludes = read_repositories( "appliances/#{appliance_name}/#{appliance_name}.appl" )
          #puts repos.inspect
          definition['repos'] += repo_lines
          all_excludes += repo_excludes
        end
      end
      puts "repos #{definition['repos'].inspect}"
      unless ( all_excludes.empty? )
        definition['exclude_clause'] = "--excludepkgs=#{all_excludes.join(',')}"
      end

      directory "#{@build_dir}/appliances/#{@simple_name}"

      file "#{@build_dir}/appliances/#{@simple_name}/#{@simple_name}.ks"=>[ "#{@build_dir}/appliances/#{@simple_name}" ] do
        template = File.dirname( __FILE__ ) + "/appliance.ks.erb"

        erb = ERB.new( File.read( template ) )
        File.open( "#{@build_dir}/appliances/#{@simple_name}/#{@simple_name}.ks", 'w' ) {|f| f.write( erb.result( definition.send( :binding ) ) ) }
      end

      for appliance_name in @appliance_names
        file "#{@build_dir}/appliances/#{@simple_name}/#{@simple_name}.ks"=>[ "rpm:#{appliance_name}" ] 
      end

      desc "Build kickstart for #{@super_simple_name} appliance"
      task "appliance:#{@simple_name}:kickstart" => [ "#{@build_dir}/appliances/#{@simple_name}/#{@simple_name}.ks" ]
    end

    def read_repositories(appliance_definition)
      definition = YAML.load_file( appliance_definition )
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

