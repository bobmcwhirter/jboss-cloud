

#task :default=>[ :appliance ]

#task :appliance do 
  #puts "Building appliance"
#end
#

$: << File.dirname( __FILE__ ) + '/lib'

require "rpms/Rakefile.rb"
require "appliances/Rakefile.rb"
