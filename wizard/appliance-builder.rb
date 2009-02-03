
puts "\nWelcome to JBoss Cloud appliance builder\n\r"

puts "Available appliances:"
Dir[ "../appliances/*/*.appl" ].each do |appliance_def|
  puts "- " + File.basename( appliance_def, '.appl' )
end

