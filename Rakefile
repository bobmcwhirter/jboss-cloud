require 'rake/clean'

require 'ostruct'
require 'open3'
require 'yaml'

JBOSS_CLOUD = OpenStruct.new( {
  :name=>'jboss-cloud',
  :version=>'1.0.0.Beta1',
  :release=>'1',
  # -- 
  :root=>File.dirname(__FILE__),
  :topdir=>File.dirname(__FILE__) + '/topdir',
} )

APPLIANCE_SOURCE_FILE = "topdir/SOURCES/#{JBOSS_CLOUD.name}-#{JBOSS_CLOUD.version}-#{JBOSS_CLOUD.release}.tar.gz" 

def build_source_dependencies( spec_file, rpm_file, version=nil, release=nil )
  File.open( spec_file).each_line do |line|
    line.gsub!( /#.*$/, '' )
    if ( line =~ /Requires: (.*)/ )
      requirement = $1.strip
      if PROVIDES_LOCALLY.keys.include?( requirement )
        file rpm_file  => [ "topdir/RPMS/noarch/#{PROVIDES_LOCALLY[requirement]}.noarch.rpm" ]
      end
    elsif ( line =~ /Source[0-9]+: (.*)/ )
      source = $1.strip
      if ( source =~ %r{http://} )
        source.gsub!( /%\{version\}/, version ) if version
        source.gsub!( /%\{release\}/, release ) if release
        source_basename = File.basename( source )

        source_file = "topdir/SOURCES/#{source_basename}"
        file rpm_file => [ source_file ]

        #desc "Grab #{source_basename}"
        file source_file do
          execute_command( "wget #{source} -O #{JBOSS_CLOUD.topdir}/SOURCES/#{source_basename} --progress=bar:mega" )
        end
      else
        source.gsub!( /%\{version\}/, version ) if version
        source.gsub!( /%\{release\}/, release ) if release
        source_basename = File.basename( source )
        source_file = "topdir/SOURCES/#{source_basename}"
        file rpm_file => [ source_file ]
        if ( source_file == APPLIANCE_SOURCE_FILE )
          #
        else
          file source_file=>[ "src/#{source_basename}" ] do
            FileUtils.cp( JBOSS_CLOUD.root + "/src/#{source}", JBOSS_CLOUD.topdir + "/SOURCES/#{source}" )
          end
        end
      end
    end
  end
end

desc "Get information on the build"
task :info do 
  puts "#{JBOSS_CLOUD.name} version #{JBOSS_CLOUD.version}"
  puts "root: #{JBOSS_CLOUD.root}"
  puts ""
  puts "Appliances"
  puts ""
  puts "Extra RPMs"
  PROVIDES_LOCALLY.keys.each do |name|
    puts " * #{name}"
  end
  puts ""
end

#directory 'topdir'
directory 'topdir/SPECS'
directory 'topdir/SOURCES'
directory 'topdir/BUILD'
directory 'topdir/RPMS'
directory 'topdir/SRPMS'
CLOBBER << 'topdir/'

directory 'tmp/'
CLEAN << 'tmp/'

namespace :base do
  task :topdir=>[ 'topdir/SPECS',
                  'topdir/SOURCES',
                  'topdir/BUILD',
                  'topdir/RPMS',
                  'topdir/SRPMS' ]

end

RPM_EXTRAS = []
PROVIDES_LOCALLY = {}

namespace :rpm do

  desc "Create the repository metadata"
  task :repodata => 'topdir/RPMS/noarch/repodata' 

  file 'topdir/RPMS/noarch/repodata'=>FileList.new( 'topdir/RPMS/noarch/*.rpm' ) do
    execute_command( "createrepo topdir/RPMS/noarch/repodata" )
  end

  namespace :extras do
    Dir[ JBOSS_CLOUD.root + '/specs/extras/*.yml' ].each do |yml|
      config = YAML.load( File.read( yml ) )
      spec_file = yml.gsub( /\.yml$/, '.spec' )
      simple_name = File.basename( yml, ".yml" )
      version = config['version']
      release = `rpm --define 'version #{version}' --specfile #{spec_file} -q --qf '%{Release}'`
      rpm_file = "topdir/RPMS/noarch/#{simple_name}-#{version}-#{release}.noarch.rpm"
      PROVIDES_LOCALLY[simple_name] = "#{simple_name}-#{version}-#{release}"

      desc "Build #{simple_name} RPM."
      task simple_name=>[ rpm_file ]

      namespace simple_name.to_sym do

        RPM_EXTRAS << rpm_file

        file rpm_file => [ 'base:topdir', spec_file ] do
          execute_command "rpmbuild --define 'version #{version}' --define '_topdir #{JBOSS_CLOUD.topdir}' --target noarch -ba #{spec_file}"
        end

        CLOBBER << rpm_file
        build_source_dependencies( spec_file, rpm_file, version )

      end # namespace <rpm>
    end # Dir[...]
  end # :extras

  desc "Build all RPMs from extras."
  task :extras=>RPM_EXTRAS

  namespace :appliance do
    Dir[ JBOSS_CLOUD.root + '/specs/appliances/*.spec' ].each do |spec_file|
      simple_name = File.basename( spec_file, "-appliance.spec" )

      rpm_file = "topdir/RPMS/noarch/#{simple_name}-appliance-#{JBOSS_CLOUD.version}-#{JBOSS_CLOUD.release}.noarch.rpm"

      desc "Build #{simple_name} appliance RPM."
      task simple_name=>[ rpm_file ]

      namespace simple_name.to_sym do
        file rpm_file => [ 'base:topdir', spec_file ] do
          execute_command "rpmbuild --define 'version #{JBOSS_CLOUD.version}' --define 'release #{JBOSS_CLOUD.release}' --define '_topdir #{JBOSS_CLOUD.topdir}' --target noarch -ba #{spec_file}"
        end
  
        build_source_dependencies( spec_file, rpm_file, JBOSS_CLOUD.version, JBOSS_CLOUD.release )
      end
    end
  end

end

namespace :appliance do

  stage_directory = "tmp/#{JBOSS_CLOUD.name}-#{JBOSS_CLOUD.version}/"

  source_files = FileList.new( 'appliances/**/*' )

  file APPLIANCE_SOURCE_FILE => [ source_files, 'base:topdir' ].flatten do
    FileUtils.rm_rf stage_directory
    FileUtils.mkdir_p stage_directory
    FileUtils.cp_r( 'appliances', stage_directory  )
    Dir.chdir( 'tmp' ) do
      execute_command( "tar zcvf #{JBOSS_CLOUD.root}/#{APPLIANCE_SOURCE_FILE} #{JBOSS_CLOUD.name}-#{JBOSS_CLOUD.version}" )
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

