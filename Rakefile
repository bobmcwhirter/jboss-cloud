require 'rake/clean'

require 'ostruct'
require 'open3'
require 'yaml'
require 'erb'
require 'rexml/document'

PROJECT = OpenStruct.new( {
  :name=>'jboss-cloud',
  :version=>'1.0.0.Beta1',
  :release=>'1',
  # -- 
  :root=>File.dirname(__FILE__),
  :build_dir=>'build',
  :topdir=>'build/topdir',
  :sources_cache_dir=>'sources-cache',
  :rpms_cache_dir=>'rpms-cache',
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
  task :repodata => "#{PROJECT.topdir}/RPMS/noarch/repodata/repomd.xml" 

  namespace :repodata do
    task :force do
      execute_command( "createrepo #{PROJECT.topdir}/RPMS/noarch" )
    end

    file "#{PROJECT.topdir}/RPMS/noarch/repodata/repomd.xml"=>FileList.new( "#{PROJECT.topdir}/RPMS/noarch/*.rpm" ) do
      execute_command( "createrepo #{PROJECT.topdir}/RPMS/noarch" )
    end
  end

  namespace :extras do
    Dir[ PROJECT.root + '/specs/extras/*.yml' ].each do |yml|
      config = YAML.load( File.read( yml ) )
      spec_file = yml.gsub( /\.yml$/, '.spec' )
      simple_name = File.basename( yml, ".yml" )
      version = config['version']
      release = nil
      Dir.chdir( "specs/extras/" ) do
        release = `rpm --define 'version #{version}' --specfile #{spec_file} -q --qf '%{Release}'`
      end
      rpm_file = "#{PROJECT.topdir}/RPMS/noarch/#{simple_name}-#{version}-#{release}.noarch.rpm"
      PROVIDES_LOCALLY[simple_name] = "#{simple_name}-#{version}-#{release}"

      desc "Build #{simple_name} RPM."
      task simple_name=>[ rpm_file ]

      namespace simple_name.to_sym do

        RPM_EXTRAS << rpm_file

        file rpm_file => [ 'base:topdir', spec_file ] do
          Dir.chdir( "specs/extras/" ) do
            execute_command "rpmbuild --define 'version #{version}' --define '_topdir #{PROJECT.root}/#{PROJECT.topdir}' --target noarch -ba #{simple_name}.spec"
          end
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
  task 'common-source'=>[ APPLIANCE_SOURCE_FILE ]

  directory "#{PROJECT.build_dir}/appliances"

  Dir[ PROJECT.root + '/specs/appliances/*.spec' ].each do |spec_file|
    simple_name = File.basename( spec_file, ".spec" )
    super_simple_name = File.basename( simple_name, "-appliance" )
    
    appliance_build_dir = "#{PROJECT.build_dir}/appliances/#{simple_name}"
    appliance_xml_file  = "#{appliance_build_dir}/#{simple_name}.xml"
    appliance_ks_file   = "#{appliance_build_dir}/#{simple_name}.ks"
    appliance_yml_file  = "kickstarts/#{simple_name}.yml"

    appliance_vmx_package  = "#{PROJECT.build_dir}/appliances/#{simple_name}-#{PROJECT.version}-#{PROJECT.release}.tgz"

    namespace simple_name do
      directory appliance_build_dir
      if ( File.exist?( appliance_yml_file ) )
        file appliance_ks_file => [ appliance_yml_file ]
      end
      file appliance_ks_file => [ appliance_build_dir, "#{appliance_build_dir}/base-pkgs.ks", "kickstarts/appliance.ks.erb" ] do
        puts "Creating kickstart for #{simple_name}"
        ks_gen = KickstartGenerator.new( "kickstarts/appliance.ks.erb", appliance_ks_file )
        ks_gen.local_repository_url = "file://#{PROJECT.root}/#{PROJECT.topdir}/RPMS/noarch"
        ks_gen.appliance_name = simple_name
        ks_gen.appliance_rpm = simple_name

        if ( File.exist?( appliance_yml_file ) ) 
          r = YAML.load_file( appliance_yml_file ) 
          ks_gen.post_script = r['post'] 
        end

        ks_gen.generate
      end
      file "#{appliance_build_dir}/base-pkgs.ks" => [ appliance_build_dir, "#{PROJECT.root}/kickstarts/base-pkgs.ks" ] do
        FileUtils.cp( "#{PROJECT.root}/kickstarts/base-pkgs.ks", "#{appliance_build_dir}/base-pkgs.ks" )
      end

      directory "#{PROJECT.build_dir}/tmp"
      file appliance_xml_file=>[ appliance_ks_file, "#{PROJECT.build_dir}/appliances", "rpm:appliance:#{super_simple_name}", "#{PROJECT.build_dir}/tmp" ] do
        Rake::Task[ 'rpm:repodata:force' ].invoke
        execute_command( "sudo PYTHONUNBUFFERED=1 appliance-creator -d -v -t #{PROJECT.root}/#{PROJECT.build_dir}/tmp --cache=#{PROJECT.rpms_cache_dir} --config #{appliance_ks_file} -o #{PROJECT.build_dir}/appliances --name #{simple_name} --vmem 1024 --vcpu 1" )
      end

      file "#{appliance_xml_file}.vmx-input"=>[ appliance_xml_file ] do
        doc = REXML::Document.new( File.read( appliance_xml_file ) )
        name_elem = doc.root.elements['name']
        name_elem.attributes[ 'version' ] = "#{PROJECT.version}-#{PROJECT.release}"
        description_elem = doc.root.elements['description']
        if ( description_elem.nil? )
          description_elem = REXML::Element.new( "description" )
          description_elem.text = "#{simple_name} Appliance\n Version: #{PROJECT.version}-#{PROJECT.release}"
          doc.root.insert_after( name_elem, description_elem )
        end
        File.open( "#{appliance_xml_file}.vmx-input", 'w' ) {|f| f.write( doc ) }
      end

      file appliance_vmx_package => [ "#{appliance_xml_file}.vmx-input" ] do
        execute_command( "virt-pack -o #{PROJECT.root}/#{PROJECT.build_dir}/appliances #{appliance_xml_file}.vmx-input" )
      end

    end

    desc "Build #{super_simple_name} appliance image"
    task super_simple_name=>[ appliance_xml_file ]

    namespace super_simple_name do
      desc "Build #{super_simple_name} appliance image for VMWare"
      task "vmx"=> [ appliance_vmx_package ] 
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
  Open3.popen3( cmd ) do |stdin, stdout, stderr|
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


class KickstartGenerator

  attr_accessor :local_repository_url
  attr_accessor :appliance_name
  attr_accessor :appliance_rpm

  attr_accessor :post_script

  def initialize(template_path, output_path)
    @template_path = template_path
    @output_path = output_path
  end

  def generate()
    erb = ERB.new( File.read( @template_path ) )
    b = binding
    File.open( @output_path, 'w' ) {|f| f.write( erb.result(b) ) }
  end

end
