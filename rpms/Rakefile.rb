$: << File.dirname( __FILE__ ) + '/../lib'

require 'build_tools'

LOCAL_CONFIG = OpenStruct.new( {
  :specs_dir   => CONFIG.rpms_dir + "/specs",
  :sources_dir => CONFIG.rpms_dir + "/sources",
})

specs = Dir[ LOCAL_CONFIG.specs_dir + '/*.spec' ]


namespace :rpm do
  task :create_topdir do
    puts "creating topdir #{CONFIG.topdir}"
    FileUtils.mkdir_p( CONFIG.topdir )
    FileUtils.mkdir_p( CONFIG.topdir + '/SOURCES' )
    FileUtils.mkdir_p( CONFIG.topdir + '/SRPMS' )
    FileUtils.mkdir_p( CONFIG.topdir + '/RPMS' )
    FileUtils.mkdir_p( CONFIG.topdir + '/SPECS' )
    FileUtils.mkdir_p( CONFIG.topdir + '/BUILD' )
  end
  
  task :copy_sources do 
    FileUtils.cp( Dir[ LOCAL_CONFIG.sources_dir + '/*' ], CONFIG.topdir + '/SOURCES/' )
  end

  task :createrepo do
    FileUtils.chdir( CONFIG.topdir + '/RPMS/noarch' ) do
      `createrepo .`
    end
  end

  task :clean do
    execute_command( "rm -rf #{CONFIG.topdir}/RPMS/*" )
    execute_command( "rm -rf #{CONFIG.topdir}/SRPMS/*" )
  end

  desc "Install RPMs under tmp/"
  task "tmp-install".to_sym

  specs.each do |spec|
    simple_name = File.basename( spec, ".spec" )
    desc "Build #{simple_name}"
    task simple_name.to_sym => [ :create_topdir, :copy_sources, "prepare_#{simple_name}_sources".to_sym ] do 
      build_rpm( spec, CONFIG.topdir )
      Rake::Task['rpm:createrepo'].invoke
    end
    task "prepare_#{simple_name}_sources".to_sym do 
      prepare_sources(spec, CONFIG.topdir, LOCAL_CONFIG.sources_dir)
    end

    desc "Install #{simple_name} under tmp/"
    task "tmp-install-#{simple_name}".to_sym do
      tmp_install( simple_name, CONFIG.topdir, CONFIG.tmp_dir )
    end
    task "tmp-install".to_sym=>[ "rpm:tmp-install-#{simple_name}".to_sym ]
  end
end

specs.each do |spec|
  simple_name = File.basename( spec, ".spec" )
  task :rpm=>[ "rpm:#{simple_name}".to_sym ]
end

