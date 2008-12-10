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

#directory 'topdir'
directory 'topdir/SPECS'
directory 'topdir/SOURCES'
directory 'topdir/BUILD'
directory 'topdir/RPMS'
directory 'topdir/SRPMS'

namespace :base do
  desc "Create topdir structure"
  task :topdir=>[ 'topdir/SPECS',
                  'topdir/SOURCES',
                  'topdir/BUILD',
                  'topdir/RPMS',
                  'topdir/SRPMS' ]
  CLOBBER << 'topdir'

end

RPM_EXTRAS = []

namespace :rpm do

  namespace :extras do
    Dir[ JBOSS_CLOUD.root + '/specs/extras/*.yml' ].each do |yml|
      config = YAML.load( File.read( yml ) )
      spec_file = yml.gsub( /\.yml$/, '.spec' )
      simple_name = File.basename( yml, ".yml" )
      version = config['version']
      release = `rpm --define 'version #{version}' --specfile #{spec_file} -q --qf '%{Release}'`
      rpm_file = "topdir/RPMS/noarch/#{simple_name}-#{version}-#{release}.noarch.rpm"

      desc "Build #{simple_name} RPM"
      task simple_name=>[ rpm_file ]

      namespace simple_name.to_sym do

        RPM_EXTRAS << rpm_file

        file rpm_file => [ 'base:topdir', spec_file ] do
          #Rake::Task["rpm:extras:#{simple_name}:fetch-source"].invoke
          puts "** Building #{rpm_file}"
          execute_command "rpmbuild --define 'version #{version}' --define '_topdir #{JBOSS_CLOUD.topdir}' --target noarch -ba #{spec_file}"
        end

        CLOBBER << rpm_file

        File.open( spec_file).each_line do |line|
          line.gsub!( /#.*$/, '' )
          if ( line =~ /Source[0-9]+: (.*)/ )
            source = $1
            puts "SOURCE #{source}"
            if ( source =~ %r{http://} )
              source.gsub!( /%\{version\}/, version )
              source_basename = File.basename( source )

              source_file = "topdir/SOURCES/#{source_basename}"
              file rpm_file => [ source_file ]

              #desc "Grab #{source_basename}"
              file source_file do
                execute_command( "wget #{source} -O #{JBOSS_CLOUD.topdir}/SOURCES/#{source_basename} --progress=bar:mega" )
              end
            else
              source.gsub!( /%\{version\}/, version )
              source_basename = File.basename( source )
              source_file = "topdir/SOURCES/#{source_basename}"
              file rpm_file => [ source_file ]
              puts "COPY SOURCE #{source_file}"
              file source_file=>[ "src/#{source_basename}" ] do
                FileUtils.cp( JBOSS_CLOUD.root + "/src/#{source}", JBOSS_CLOUD.topdir + "/SOURCES/#{source}" )
              end
            end
          end
        end

      end # namespace <rpm>
    end # Dir[...]
  end # :extras

  desc "Build all RPMs from extras"
  task :extras=>RPM_EXTRAS

  namespace :appliance do
    appliance_source_file = "topdir/SOURCES/#{JBOSS_CLOUD.name}-#{JBOSS_CLOUD.version}-#{JBOSS_CLOUD.release}.tar.gz" 
    desc "Create the source for appliances"
    file appliance_source_file do
      execute_command( "tar zcvf #{appliance_source_file} ./appliances" )
    end
  end

end


namespace :kickstart do
end

## -- 
## -- 
## -- 
## -- 
## -- 
## -- 

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
