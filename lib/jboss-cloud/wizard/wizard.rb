require 'jboss-cloud/exec'

module JBossCloudWizard
  class Wizard

    AVAILABLE_OUTPUT_FORMATS = ["RAW",  "VMware Enterprise (ESX/ESXi)", "VMware Personal (Player, Workstation, Server)"]

    def initialize(options)
      @options = options
      @available_appliances = Array.new
      @mem_size = 1024
      @disk_size = 2048
      @network = "NAT"
      @output_format = 1
    end

    def start
      init_appliances

      # appliance
      step1

      # memory - currently commented - we're using 1024 for now
      # step2

      # disk - currently commented - we're using 2GB disks for now
      # step3

      # output type
      step4

      # network
      # 
      # VMware
      if (@output_format.to_i == 2 or @output_format.to_i == 3)
        step5
      end

      unless verified?
        start
        exit(0)
      end
      
      build
    end

    protected

    # selecting appliance to build
    def step1
      list_appliances

      puts "\n### Which appliance do you want to build?"

      appliance = gets.chomp

      step1 unless valid_appliance_name?( appliance )
    end

    # selecting memory size for appliance
    def step2
      print "\n### How much RAM (in MB) do you want in your appliance? [1024] "

      memsize = gets.chomp

      step2 unless valid_memsize?( memsize )
    end

    # selecting right network name/type
    def step5
      puts "\n### Specify your network name"

      network = gets.chomp
      
      # should be the best value
      if network.length == 0
        @network = "NAT"
      else
        @network = network
      end

    end

    # selecting output format
    def step4
      list_output_formats

      print "\n### Specify output format (1-3) [1] "

      output_format = gets.chomp

      step4 unless valid_output_format?( output_format )
    end

    def verified?
      puts "\n### Selected options:\r\n"

      puts "\nAppliance:\t#{@appliance}"
      puts "Memory:\t\t#{@mem_size}MB"
      puts "Network:\t#{@network}" if (@output_format.to_i == 2 or @output_format.to_i == 3)
      puts "Disk:\t\t#{@disk_size/1024}GB"
      puts "Output format:\t#{AVAILABLE_OUTPUT_FORMATS[@output_format.to_i-1]}"

      return is_correct?
    end

    def is_correct?
      print "\nIs this correct? [Y/n] "

      correct_answer = gets.chomp

      return true if correct_answer.length == 0
      return is_correct? unless (correct_answer.length == 1)
      return is_correct? if (correct_answer.upcase != "Y" and correct_answer.upcase != "N")

      if (correct_answer.upcase == "Y")
        return true
      else
        return false
      end
    end

    def build
      puts "\nBuilding #{@appliance}... (this may take a while)"

      puts "Wizard runs in quiet mode, messages are not shown. Add '-V' for verbose.\r\n\r\n" unless @options.verbose

      command = "rake appliance:#{@appliance}" if @output_format.to_i == 1
      command = "NETWORK_NAME=\"#{@network}\" rake appliance:#{@appliance}:vmware:enterprise" if @output_format.to_i == 2
      command = "NETWORK_NAME=\"#{@network}\" rake appliance:#{@appliance}:vmware:personal" if @output_format.to_i == 3

      unless execute("#{command}", @options.verbose)
        puts "Build failed"
        exit(1)
      end

      puts "Build was successful. Check #{Dir.pwd}/build/appliances/ folder for output files."
    end

    def init_appliances
      @available_appliances.clear

      Dir[ "appliances/*/*.appl" ].each do |appliance|
        @available_appliances.push( "#{File.basename( appliance, '.appl' )}" )
      end
    end

    def list_appliances
      puts "\nAvailable appliances:"

      @available_appliances.each do |appliance|
        puts "- " + appliance
      end
    end

    def list_output_formats
      puts "\nAvailable output formats:"

      nb = 0

      AVAILABLE_OUTPUT_FORMATS.each do |output_format|
        puts "#{nb += 1}. #{output_format}"
      end      
    end

    def valid_output_format? ( output_format )
      # default - RAW
      if output_format.length == 0
        @output_format = 1
        return true
      end

      if output_format.to_i == 0
        puts "#{output_format} is not a valid value"
        return false
      end

      if output_format.to_i >= 1 and output_format.to_i <= 3
        @output_format = output_format
        return true
      end

      return false
    end

    def valid_memsize?( memsize )

      if memsize.to_i == 0
        puts "#{memsize} is not a valid value" unless memsize.length == 0
        return false
      end

      if @appliance == "jboss-as5-appliance" or @appliance == "build-appliance"
        min_memsize = 512
      else
        min_memsize = 128
      end

      if (memsize.to_i % 128 > 0)
        puts "Memory size should be multiplicity of 128"
        return false
      end

      # todo add reconfiguration of JBoss AS run.conf file

      # Minimal amount of RAM for appliances:
      # build-appliance           - 512
      # jboss-as5-appliance       - 512
      # postgis-appliance         - 128
      # httpd-appliance           - 128
      # jboss-jgroups-appliance   - 128
      
      if (memsize.to_i < min_memsize)
        puts "#{memsize}MB is not enough for #{@appliance}, please give >= #{min_memsize}"
        return false
      end

      @mem_size = memsize
      return true
    end

    def valid_appliance_name?(appliance)
      return false unless ( @available_appliances.include?( appliance ))

      @appliance = appliance
      return true
    end

  end
end

