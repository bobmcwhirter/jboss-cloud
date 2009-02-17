require 'jboss-cloud/exec'
require 'jboss-cloud/config'
require 'jboss-cloud/wizard/step_appliance'
require 'jboss-cloud/wizard/step_disk'
require 'yaml'
require 'fileutils'

module JBossCloudWizard
  class Wizard

    AVAILABLE_OUTPUT_FORMATS = ["RAW",  "VMware Enterprise (ESX/ESXi)", "VMware Personal (Player, Workstation, Server)"]
    AVAILABLE_ARCHES = [ "i386", "x86_64" ]

    def initialize(options)
      @options = options
      @available_appliances = Array.new
      @appliance_configs = Hash.new

      @config_dir = "/home/#{ENV['USER']}/.jboss-cloud/configs"

      if !File.exists?(@config_dir) && !File.directory?(@config_dir)
        puts "Config dir doesn't exists. Creating new." if @options.verbose
        FileUtils.mkdir_p @config_dir
      end     
    end

    def read_available_appliances
      @available_appliances.clear

      puts "\nReading available appliances..." if @options.verbose

      Dir[ "appliances/*/*.appl" ].each do |appliance_def|
        @available_appliances.push( File.basename( appliance_def, '.appl' ))
      end

      puts "No appliances found" if @options.verbose and @available_appliances.size == 0
      puts "Found #{@available_appliances.size} #{@available_appliances.size > 1 ? "appliances" : "appliance"} (#{@available_appliances.join(", ")})" if @options.verbose and @available_appliances.size > 0
    end

    def read_configs
      read_available_appliances

      @appliance_configs.clear

      puts "\nReading saved configurations..." if @options.verbose

      Dir[ "#{@config_dir}/*.cfg" ].each do |config_def|
        config_name = File.basename( config_def, '.cfg' )

        @appliance_configs.store( config_name, YAML.load_file( config_def ))
      end

      puts "No saved configs found" if @options.verbose and @appliance_configs.size == 0
      puts "Found #{@appliance_configs.size} saved #{@appliance_configs.size > 1 ? "configs" : "config"} (#{@appliance_configs.keys.join(", ")})" if @options.verbose and @appliance_configs.size > 0
    end

    def step_appliance
      @current_appliance_config = StepAppliance.new(@available_appliances).ask
      @previous_appliance_config = @previous_appliance_configs[@current_appliance_config.name + "-" + @current_appliance_config.arch]
    end

    def step_disk
      StepDisk.new(@current_appliance_config, @previous_appliance_config).ask
    end

    def display_configs
      return if @appliance_configs.size == 0

      puts "### Saved configs:"

      i = 0

      @appliance_configs.keys.each do |config|
        puts "    #{i+=1}. #{config}"
      end

    end

    def select_config
      

      return if @appliance_configs.size == 0

      display_configs

      print "\n### Select saved config or press ENTER to create a fresh one (1-#{@appliance_configs.size}) "

      selected_config = gets.chomp

      selected_config
    end

    def start

      puts "\n###\r\n### Welcome to JBoss Cloud appliance builder wizard\r\n###\r\n\r\n"

      read_configs

      puts select_config

      abort

      step_appliance
      step_disk
      

      

      abort
      # appliance
      
      #puts @available_appliances[@appliance.to_i]

      
      # memory - currently commented - we're using 1024 for now
      #step2

      abort
      # disk
      step3

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

    end

    # selecting memory size for appliance
    def step2
      puts_question "How much RAM (in MB) do you want in your appliance? [1024]"

      memsize = gets.chomp

      step2 unless valid_memsize?( memsize )
    end

    #selecting disk size


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
      puts "Disk:\t\t#{@disk_size.to_i/1024}GB"
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

      command = "DISK_SIZE=\"#{@disk_size}\" NETWORK_NAME=\"#{@network}\" "

      command += "rake appliance:#{@appliance}" if @output_format.to_i == 1
      command += "rake appliance:#{@appliance}:vmware:enterprise" if @output_format.to_i == 2
      command += "rake appliance:#{@appliance}:vmware:personal" if @output_format.to_i == 3

      unless execute("#{command}", @options.verbose)
        puts "Build failed"
        exit(1)
      end

      puts "Build was successful. Check #{Dir.pwd}/build/appliances/ folder for output files."
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

      if @appliance == "jboss-as5-appliance" or @appliance == "meta-appliance"
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
      # meta-appliance            - 512
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



  end
end

