require 'rake/clean'

require 'ostruct'
require 'open3'
require 'yaml'

JBOSS_CLOUD = OpenStruct.new( {
  :name=>'jboss-cloud',
  :version=>"1.0.0.Beta1",
  # -- 
  :root=>File.dirname(__FILE__),
  :topdir=>File.dirname(__FILE__) + '/topdir',
} )

task :info do 
  puts "#{JBOSS_CLOUD.name} version #{JBOSS_CLOUD.version}"
  puts "root: #{JBOSS_CLOUD.root}"
end

directory JBOSS_CLOUD.topdir

RPM_EXTRAS = []

namespace :rpm do

  desc "Build all extras RPMs"

  namespace :extras do
    Dir[ JBOSS_CLOUD.root + '/specs/extras/*.yml' ].each do |yml|
      config = YAML.load( File.read( yml ) )
      spec_file = yml.gsub( /\.yml$/, '.spec' )
      simple_name = File.basename( yml, ".yml" )
      version = config['version']
      release = `rpm --define 'version #{version}' --specfile #{spec_file} -q --qf '%{Release}'`
      namespace simple_name.to_sym do

        rpm_file = "topdir/RPMS/noarch/#{simple_name}-#{version}-#{release}.noarch.rpm"
        RPM_EXTRAS << rpm_file

        desc "Build #{simple_name} RPM"
        file rpm_file => [ JBOSS_CLOUD.topdir, spec_file ] do
          Rake::Task["rpm:extras:#{simple_name}:fetch-source"].invoke
          puts "** Building #{rpm_file}"
          execute_command "rpmbuild --define 'version #{version}' --define '_topdir #{JBOSS_CLOUD.topdir}' --target noarch -ba #{spec_file}"
        end

        CLOBBER << rpm_file


        desc "Fetch sources for #{simple_name}"
        task "fetch-source" do
          File.open( spec_file).each_line do |line|
            if ( line =~ /Source[0-9]+: (.*)/ )
              source = $1
              if ( source =~ %r{http://} )
                source.gsub!( /%\{version\}/, version )
                source_basename = File.basename( source )
                if ( ! File.exist?( JBOSS_CLOUD.topdir + "/SOURCES/#{source_basename}" ) )
                  execute_command( "wget #{source} -O #{JBOSS_CLOUD.topdir}/sources/#{source_basename}" )
                end
              else
                if ( File.exist?( JBOSS_CLOUD.root + "/src/#{source}" ) )
                  FileUtils.cp( JBOSS_CLOUD.root + "/src/#{source}", JBOSS_CLOUD.topdir + "/sources/#{source}" )
                end
              end
            end
          end
        end

      end # namespace <rpm>
    end # Dir[...]
  end # :extras

  task :extras=>RPM_EXTRAS

  namespace :appliance do
  end

end


namespace :kickstart do
end

def execute_command(cmd)
  puts "CMD [\n\t#{cmd}\n]"
  old_trap = trap("INT") do
    puts "caught SIGINT, shutting down"
  end
  pid = Open3.popen3( cmd ) do |stdin, stdout, stderr|
    #stdin.close
    threads = []
    threads << Thread.new(stdout) do |input_str|
      while ( ( l = input_str.gets ) != nil )
        puts l 
      end
    end
    threads << Thread.new(stderr) do |input_str|
      while ( ( l = input_str.gets ) != nil )  
        puts l 
      end
    end
    threads.each{|t|t.join}
  end
  trap("INT", old_trap )
end
