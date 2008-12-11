require 'rake/clean'

require 'ostruct'
require 'open3'
require 'yaml'

PROJECT = OpenStruct.new( {
  :name=>'jboss-cloud',
  :version=>'1.0.0.Beta1',
  :release=>'1',
  # -- 
  :root=>File.dirname(__FILE__),
  :build_dir=>'build',
  :topdir=>'build/topdir',
  :sources_cache_dir=>'sources-cache',
} )

CLEAN << PROJECT.build_dir

APPLIANCE_SOURCE_FILE = "#{PROJECT.topdir}/SOURCES/#{PROJECT.name}-#{PROJECT.version}-#{PROJECT.release}.tar.gz" 

def build_source_dependencies( spec_file, rpm_file, version=nil, release=nil )
  File.open( spec_file).each_line do |line|
    line.gsub!( /#.*$/, '' )
    if ( line =~ /Requires: (.*)/ )
      requirement = $1.strip
      if PROVIDES_LOCALLY.keys.include?( requirement )
        file rpm_file  => [ "#{PROJECT.topdir}/RPMS/noarch/#{PROVIDES_LOCALLY[requirement]}.noarch.rpm" ]
      end
    elsif ( line =~ /Source[0-9]+: (.*)/ )
      source = $1.strip
      if ( source =~ %r{http://} )
        source.gsub!( /%\{version\}/, version ) if version
        source.gsub!( /%\{release\}/, release ) if release
        source_basename = File.basename( source )

        source_file       = "#{PROJECT.topdir}/SOURCES/#{source_basename}"
        source_cache_file = "#{PROJECT.sources_cache_dir}/#{source_basename}"

        file rpm_file => [ source_file ]

        file source_file => [ 'base:topdir' ] do
          if ( ! File.exist?( source_cache_file ) ) 
            FileUtils.mkdir_p( PROJECT.sources_cache_dir )
            execute_command( "wget #{source} -O #{source_cache_file} --progress=bar:mega" )
          end
          FileUtils.cp( source_cache_file, source_file )
        end

        
      else
        source.gsub!( /%\{version\}/, version ) if version
        source.gsub!( /%\{release\}/, release ) if release
        source_basename = File.basename( source )
        source_file = "#{PROJECT.topdir}/SOURCES/#{source_basename}"
        file rpm_file => [ source_file ]
        if ( source_file == APPLIANCE_SOURCE_FILE )
          #
        else
          file source_file=>[ "src/#{source_basename}" ] do
            FileUtils.cp( PROJECT.root + "/src/#{source}", PROJECT.topdir + "/SOURCES/#{source}" )
          end
        end
      end
    end
  end
end

desc "Get information on the build"
task :info do 
  puts "#{PROJECT.name} version #{PROJECT.version}"
  puts "root: #{PROJECT.root}"
  puts ""
  puts "Appliances"
  puts ""
  puts "Extra RPMs"
  PROVIDES_LOCALLY.keys.each do |name|
    puts " * #{name}"
  end
  puts ""
end

directory "#{PROJECT.topdir}/SPECS"
directory "#{PROJECT.topdir}/SOURCES"
directory "#{PROJECT.topdir}/BUILD"
directory "#{PROJECT.topdir}/RPMS"
directory "#{PROJECT.topdir}/SRPMS"

namespace :base do
  task :topdir=>[ "#{PROJECT.topdir}/SPECS",
                  "#{PROJECT.topdir}/SOURCES",
                  "#{PROJECT.topdir}/BUILD",
                  "#{PROJECT.topdir}/RPMS",
                  "#{PROJECT.topdir}/SRPMS" ]

end

RPM_EXTRAS = []
PROVIDES_LOCALLY = {}

namespace :rpm do

  desc "Create the repository metadata"
  task :repodata => "#{PROJECT.topdir}/RPMS/noarch/repodata" 

  file "#{PROJECT.topdir}/RPMS/noarch/repodata"=>FileList.new( "#{PROJECT.topdir}/RPMS/noarch/*.rpm" ) do
    execute_command( "createrepo #{PROJECT.topdir}/RPMS/noarch" )
  end

  namespace :extras do
    Dir[ PROJECT.root + '/specs/extras/*.yml' ].each do |yml|
      config = YAML.load( File.read( yml ) )
      spec_file = yml.gsub( /\.yml$/, '.spec' )
      simple_name = File.basename( yml, ".yml" )
      version = config['version']
      release = `rpm --define 'version #{version}' --specfile #{spec_file} -q --qf '%{Release}'`
      rpm_file = "#{PROJECT.topdir}/RPMS/noarch/#{simple_name}-#{version}-#{release}.noarch.rpm"
      PROVIDES_LOCALLY[simple_name] = "#{simple_name}-#{version}-#{release}"

      desc "Build #{simple_name} RPM."
      task simple_name=>[ rpm_file ]

      namespace simple_name.to_sym do

        RPM_EXTRAS << rpm_file

        file rpm_file => [ 'base:topdir', spec_file ] do
          execute_command "rpmbuild --define 'version #{version}' --define '_topdir #{PROJECT.root}/#{PROJECT.topdir}' --target noarch -ba #{spec_file}"
        end

        build_source_dependencies( spec_file, rpm_file, version )

      end # namespace <rpm>
    end # Dir[...]
  end # :extras

  desc "Build all RPMs from extras."
  task :extras=>RPM_EXTRAS

  namespace :appliance do
    Dir[ PROJECT.root + '/specs/appliances/*.spec' ].each do |spec_file|
      simple_name = File.basename( spec_file, "-appliance.spec" )

      rpm_file = "#{PROJECT.topdir}/RPMS/noarch/#{simple_name}-appliance-#{PROJECT.version}-#{PROJECT.release}.noarch.rpm"

      desc "Build #{simple_name} appliance RPM."
      task simple_name=>[ rpm_file ]

      namespace simple_name.to_sym do
        file rpm_file => [ 'base:topdir', spec_file ] do
          execute_command "rpmbuild --define 'version #{PROJECT.version}' --define 'release #{PROJECT.release}' --define '_topdir #{PROJECT.root}/#{PROJECT.topdir}' --target noarch -ba #{spec_file}"
        end
  
        build_source_dependencies( spec_file, rpm_file, PROJECT.version, PROJECT.release )
      end
    end
  end

end

namespace :appliance do

  stage_directory = "#{PROJECT.build_dir}/#{PROJECT.name}-#{PROJECT.version}/"

  source_files = FileList.new( 'appliances/**/*' )

  file APPLIANCE_SOURCE_FILE => [ source_files, 'base:topdir' ].flatten do
    FileUtils.rm_rf stage_directory
    FileUtils.mkdir_p stage_directory
    FileUtils.cp_r( 'appliances', stage_directory  )
    Dir.chdir( PROJECT.build_dir ) do
      execute_command( "tar zcvf #{PROJECT.root}/#{APPLIANCE_SOURCE_FILE} #{PROJECT.name}-#{PROJECT.version}" )
    end
  end

  desc "Create the source tarball for appliances."
  task :source=>[ APPLIANCE_SOURCE_FILE ]
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
  #puts "CMD [\n\t#{cmd}\n]"
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

