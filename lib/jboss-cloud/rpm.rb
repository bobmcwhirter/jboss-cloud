require 'rake/tasklib'

module JBossCloud
  class RPM < Rake::TaskLib

    def self.provides
      @provides ||= {}
    end

    def initialize(topdir, spec_file)
      @topdir = topdir
      @spec_file = spec_file
      define
    end

    def define
      simple_name = File.basename( @spec_file, ".spec" )
      release = nil
      version = nil
      Dir.chdir( File.dirname( @spec_file ) ) do
        release = `rpm --specfile #{simple_name}.spec -q --qf '%{Release}'`
        version = `rpm --specfile #{simple_name}.spec -q --qf '%{Version}'`
      end
      rpm_file = "#{@topdir}/RPMS/noarch/#{simple_name}-#{version}-#{release}.noarch.rpm"
      JBossCloud::RPM.provides[simple_name] = "#{simple_name}-#{version}-#{release}"

      desc "Build #{simple_name} RPM."
      task "rpm:#{simple_name}"=>[ rpm_file ]

      file rpm_file => [ 'rpm:topdir', @spec_file ] do
        root = `pwd`.strip
        Dir.chdir( File.dirname( @spec_file ) ) do
          execute_command "rpmbuild --define '_topdir #{root}/#{@topdir}' --target noarch -ba #{simple_name}.spec"
        end
      end

      build_source_dependencies( rpm_file, version, release )
    end
    

    def handle_requirement(rpm_file, requirement)
      if JBossCloud::RPM.provides.keys.include?( requirement )
        file rpm_file  => [ "#{@topdir}/RPMS/noarch/#{JBossCloud::RPM.provides[requirement]}.noarch.rpm" ]
      end
    end

    def handle_source(rpm_file, source, version, release)
      source = substitute_version_info( source, version, release )
      if ( source =~ %r{http://} )
        handle_remote_source( rpm_file, source )
      else
        handle_local_source( rpm_file, source )
      end
    end

    def handle_local_source(rpm_file, source)
      source_basename = File.basename( source )
      source_file     = "#{@topdir}/SOURCES/#{source_basename}"

      file rpm_file => [ source_file ]
 
      #if ( source_file == APPLIANCE_SOURCE_FILE )
      #  nothing
      # else
       
      file source_file=>[ "src/#{source_basename}" ] do
        FileUtils.cp( "#{JBossCloud::ImageBuilder.config.root}/src/#{source}", "#{@topdir}/SOURCES/#{source_basename}" )
      end
    
    end

    def handle_remote_source(rpm_file, source)
      source_basename = File.basename( source )

      source_file       = "#{@topdir}/SOURCES/#{source_basename}"
      source_cache_file = "#{JBossCloud::ImageBuilder.config.sources_cache_dir}/#{source_basename}"

      file rpm_file => [ source_file ]

      file source_file => [ 'rpm:topdir' ] do
        if ( ! File.exist?( source_cache_file ) )
          FileUtils.mkdir_p( JBossCloud::ImageBuilder.config.sources_cache_dir )
          execute_command( "wget #{source} -O #{source_cache_file} --progress=bar:mega" )
        end
        FileUtils.cp( source_cache_file, source_file )
      end
    end

    def substitute_version_info(str, version=nil, release=nil)
      s = str.dup
      s.gsub!( /%\{version\}/, version ) if version
      s.gsub!( /%\{release\}/, release ) if release
      s
    end

    def build_source_dependencies( rpm_file, version=nil, release=nil )
      File.open( @spec_file).each_line do |line|
        line.gsub!( /#.*$/, '' )
        if ( line =~ /Requires: (.*)/ )
          requirement = $1.strip
          handle_requirement( rpm_file, requirement )
        elsif ( line =~ /Source[0-9]+: (.*)/ )
          source = $1.strip
          handle_source( rpm_file, source, version, release  )
        end
      end
    end
  end
end
