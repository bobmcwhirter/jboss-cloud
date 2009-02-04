require 'jboss-cloud/exec'

module JBossCloudWizard
  class Wizard
    def initialize(options)
      @options = options
      @available_appliances = Array.new
    end

    def start
      init_appliances
      list_appliances
      
      step1
      
      build
    end

    protected

    def step1
      puts "\nWhich appliance do you want to build?"

      appliance = gets.chomp

      step1 unless valid_appliance_name?( appliance )
    end

    def build
      puts "\nBuilding #{@appliance}..."

      puts "Wizard runs in quiet mode, messages are not shown. Add '-V' for verbose.\r\n\r\n" unless @options.verbose

      unless execute("rake appliance:#{@appliance}", @options.verbose)
        puts "Build failed"
        exit(1)
      end

      puts "Bild was successful. Check #{Dir.pwd}/build/appliances/ folder for output files."
    end

    def init_appliances
      Dir[ "appliances/*/*.appl" ].each do |appliance|
        @available_appliances.push( "#{File.basename( appliance, '.appl' )}" )
      end
    end

    def list_appliances
      puts "Available appliances:"

      @available_appliances.each do |appliance|
        puts "- " + appliance
      end
    end

    def valid_appliance_name?(appliance)
      return false unless ( @available_appliances.include?( appliance ))

      @appliance = appliance
      return true
    end

  end
end

