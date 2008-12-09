
require 'open3'
require 'find'
require 'ostruct'

root = File.expand_path( File.dirname( __FILE__ ) + '/..' )

CONFIG = OpenStruct.new( {
  :root           => root,
  :rpms_dir       => root + "/rpms",
  :appliances_dir => root + "/appliances",
  :tmp_dir        => root + "/tmp",
  :topdir         => root + "/build-topdir",
  :target_dir     => root + "/target",
} )


def tmp_install(simple_name, topdir, tmp_dir)
  simple_name_regexp = Regexp.new( Regexp.escape( simple_name ) )
  Find.find( topdir + "/RPMS/noarch" ) do |f|
    if ( f =~ simple_name_regexp )
      FileUtils.mkdir_p( "#{tmp_dir}/rpm-install" )
      Dir.chdir( "#{tmp_dir}/rpm-install" ) do 
        execute_command( "rpm2cpio #{f} | cpio -iv" )
      end
    end
  end
end

def build_rpm(spec, topdir)
  puts "Buiding RPM from #{spec} in #{topdir}"
  execute_command "rpmbuild --define '_topdir #{topdir}' --target noarch -ba #{spec}"
end

def prepare_sources(spec, topdir, sources_dir)
  File.open(spec, "r" ) do |f|
    name    = nil
    version = nil
    f.each_line do |line|
      if ( line =~ /%define version (.+)$/ )
        version = $1.strip 
        puts "VERSION IS #{version}"
      elsif ( line =~ /%define name (.+)$/ )
        name = $1.strip 
        puts "NAME IS #{name}"
      elsif ( line =~ /^Source([0-9]*):(.*)$/ )
        source = $2.strip
        puts "source -> [#{source}]"
        source.gsub!( /%\{version\}/, version )
        source.gsub!( /%\{name\}/, name )
        if ( source =~ %r{^http://} ) 
          fetch_source( source, topdir )
        else
          copy_source( source, topdir, sources_dir )
        end
      end
    end
  end
end

def copy_source(source, topdir, sources_dir )
  FileUtils.cp( "#{sources_dir}/#{source}",  topdir + '/SOURCES/' )
end

def fetch_source(source, topdir)
  simple_source = File.basename( source )
  puts "checking on #{simple_source}"
  if ( File.exist?( topdir + "/SOURCES/#{simple_source}" ) )
    return
  end
  execute_command( "wget #{source} -O #{topdir}/SOURCES/#{simple_source}" )
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


