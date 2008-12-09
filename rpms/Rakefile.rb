require 'open3'
require 'find'

root = File.expand_path( File.dirname( __FILE__ ) + '/..' )

rpms_dir    = root + "/rpms"
tmp_dir     = root + "/tmp"
specs_dir   = rpms_dir + "/specs"
sources_dir = rpms_dir + "/sources"

topdir = root + "/build-topdir"

target = root + "/target"

#task :default=>[ :rpm, :createrepo ]
  
specs = Dir[ specs_dir + '/*.spec' ]

namespace :rpm do
  task :create_topdir do
    puts "creating topdir #{topdir}"
    FileUtils.mkdir_p( topdir )
    FileUtils.mkdir_p( topdir + '/SOURCES' )
    FileUtils.mkdir_p( topdir + '/SRPMS' )
    FileUtils.mkdir_p( topdir + '/RPMS' )
    FileUtils.mkdir_p( topdir + '/SPECS' )
    FileUtils.mkdir_p( topdir + '/BUILD' )
  end
  
  task :copy_sources do 
    FileUtils.cp( Dir[ sources_dir + '/*' ], topdir + '/SOURCES/' )
  end

  desc "Install RPMs under tmp/"
  task "tmp-install".to_sym

  specs.each do |spec|
    simple_name = File.basename( spec, ".spec" )
    desc "Build #{simple_name}"
    task simple_name.to_sym => [ :create_topdir, :copy_sources, "prepare_#{simple_name}_sources".to_sym ] do 
      build_rpm( spec, topdir )
    end
    task "prepare_#{simple_name}_sources".to_sym do 
      prepare_sources(spec, topdir, sources_dir)
    end

    desc "Install #{simple_name} under tmp/"
    task "tmp-install-#{simple_name}".to_sym do
      tmp_install( simple_name, topdir, tmp_dir )
    end
    task "tmp-install".to_sym=>[ "rpm:tmp-install-#{simple_name}".to_sym ]
  end
end

specs.each do |spec|
  simple_name = File.basename( spec, ".spec" )
  task :rpm=>[ "rpm:#{simple_name}".to_sym ]
end


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
    version = nil
    f.each_line do |line|
      if ( line =~ /%define version (.+)$/ )
        version = $1.strip 
        puts "VERSION IS #{version}"
      elsif ( line =~ /^Source([0-9]*):(.*)$/ )
        source = $2.strip
        puts "source -> [#{source}]"
        source.gsub!( /%\{version\}/, version )
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


=begin

namespace :rpm do
  [ 'jbossas', 'jboss-rails' ].each do |spec|

    desc "Build #{spec} RPM"
    task spec.to_sym=>[ "#{spec}:build".to_sym ] 

    namespace spec.to_sym do
      task :build=>[:create_topdir, :copy_sources] do
        `rpmbuild --define '_topdir #{topdir}' -ba #{root}/specs/#{spec}.spec`
        Rake::Task['createrepo'].invoke
      end
      task :copy_sources do
        if ( File.exist?( root + "/sources/#{spec}" ) ) 
          FileUtils.cp_r( root + "/sources/#{spec}/.", topdir + '/SOURCES' )
        end
      end
    end
  end
end

task :rpm=>[ :copy_sources ] do
  `rpmbuild --define '_topdir #{topdir}' -ba #{root}/specs/jbossas.spec`
end

task :createrepo=>[:create_topdir] do
  FileUtils.chdir( topdir + '/RPMS/noarch' ) do
    `createrepo .`
  end
end

task :'rpm:jboss-rails:copy_sources' do 
  if ( File.exist?( '../jboss-rails/target/jboss-rails-deployer.jar' ) )
    puts "copying deployer from sibling"
    FileUtils.cp( '../jboss-rails/target/jboss-rails-deployer.jar', topdir +'/SOURCES' )
  else
    puts "no deployer to copy from sibling"
  end
end
=end
