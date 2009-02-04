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
      step2
      
      build
    end

    protected

    # selecting appliance to build
    def step1
      puts "\nWhich appliance do you want to build?"

      appliance = gets.chomp

      step1 unless valid_appliance_name?( appliance )
    end

    # selecting memory size for appliance
    def step2
      print "\nHow much RAM (in MB) do you want in your appliance? [1024] "

      memsize = gets.chomp

      step2 unless valid_memsize?( memsize )
    end


    def build
      puts "\nBuilding #{@appliance}..."

      puts "Wizard runs in quiet mode, messages are not shown. Add '-V' for verbose.\r\n\r\n" unless @options.verbose

      unless execute("rake appliance:#{@appliance}", @options.verbose)
        puts "Build failed"
        exit(1)
      end

      puts "Build was successful. Check #{Dir.pwd}/build/appliances/ folder for output files."
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

    def valid_memsize?(memsize)

      if memsize.to_i == 0
        puts "#{memsize} is not a valid value" unless memsize.length == 0
        return false
      end

      if @appliance == "jboss-as5-appliance"
        min_memsize = 512
      else
        min_memsize = 128
      end

      if (memsize.to_i % 128 > 0)
        puts "Memory size should be multiplicity of 128"
        return false
      end

      # Minimal amount of RAM for appliances:
      # jboss-as5-appliance       - 512
      # postgis-appliance         - 128
      # httpd-appliance           - 128
      # jboss-jgroups-appliance   - 128
      
      if (memsize.to_i < min_memsize)
        puts "#{memsize}MB is not enough for #{@appliance}, please give >= #{min_memsize}"
        return false
      end

      @memsize = memsize
      return true
    end

    def valid_appliance_name?(appliance)
      return false unless ( @available_appliances.include?( appliance ))

      @appliance = appliance
      return true
    end

  end
end

