$: << File.dirname( __FILE__ ) + '/../lib'

require 'build_tools.rb'
require 'rake/packagetask'

LOCAL_CONFIG = OpenStruct.new( {
  :specs_dir      => CONFIG.appliances_dir + "/specs",
  :sources_dir    => CONFIG.appliances_dir + "/appliances",
  :kickstarts_dir => CONFIG.appliances_dir + "/kickstarts",
})

specs = Dir[ LOCAL_CONFIG.specs_dir + '/*.spec' ]

namespace :appliance do
  task :create_topdir do
    puts "creating topdir #{CONFIG.topdir}"
    FileUtils.mkdir_p( CONFIG.topdir )
    FileUtils.mkdir_p( CONFIG.topdir + '/SOURCES' )
    FileUtils.mkdir_p( CONFIG.topdir + '/SRPMS' )
    FileUtils.mkdir_p( CONFIG.topdir + '/RPMS' )
    FileUtils.mkdir_p( CONFIG.topdir + '/SPECS' )
    FileUtils.mkdir_p( CONFIG.topdir + '/BUILD' )
  end
  
  task :createrepo do
    FileUtils.chdir( CONFIG.topdir + '/RPMS/noarch' ) do
      `createrepo .`
    end
  end

  task :clean do
    execute_command( "rm -rf #{CONFIG.topdir}/RPMS/*-appliance*" )
    execute_command( "rm -rf #{CONFIG.topdir}/SRPMS/*-appliance" )
  end

  specs.each do |spec|
    simple_name = File.basename( spec, "-appliance.spec" )
    desc "Build #{simple_name}"
    task simple_name.to_sym => [ :create_topdir, "prepare_#{simple_name}_sources".to_sym ] do 
      build_rpm( spec, CONFIG.topdir )
      Rake::Task['appliance:createrepo'].invoke
    end
    task "prepare_#{simple_name}_sources".to_sym => [ "appliance:package".to_sym ] do 
      FileUtils.cp CONFIG.target_dir + "/pkg/#{simple_name}-appliance-tmp.tar.gz", CONFIG.topdir + "/SOURCES"
    end

    desc "Package sources for #{simple_name}"
    Rake::PackageTask.new( simple_name + "-appliance", "tmp") do |pkg|
        file_list = ["appliances/#{simple_name}-appliance/**/*" ]
        pkg.package_dir = CONFIG.target_dir + "/pkg"
        pkg.need_tar_gz = true
        pkg.package_files.include(file_list)
    end 
  end
end

specs.each do |spec|
  simple_name = File.basename( spec, ".spec" )
  task :rpm=>[ "rpm:#{simple_name}".to_sym ]
end

