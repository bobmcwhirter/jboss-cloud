require 'jboss-cloud/wizard/step'

module JBossCloudWizard
  class StepMemory < Step
    def initialize(appliance_config, previous_appliance_config)
      @appliance_config = appliance_config
      @previous_appliance_config = previous_appliance_config
    end

    def ask
      ask_for_disk
    end

    def ask_for_disk
      print "\n#{banner} How big should be the disk (in MB)? [2048] "

      disk_size = gets.chomp

      ask_for_disk unless valid_disk_size?( disk_size )
    end

    def valid_disk_size?( disk_size )
      if (disk_size.length == 0)
        disk_size = 2048
      end

      if disk_size.to_i == 0
        puts "Sorry, #{disk_size} is not a valid value" unless disk_size.length == 0
        return false
      end

      if @appliance == "meta-appliance"
        min_disk_size = 10240
      else
        min_disk_size = 2048
      end

      if (disk_size.to_i % 1024 > 0)
        puts "Disk size should be multiplicity of 1024MB"
        return false
      end

      if (disk_size.to_i < min_disk_size)
        puts "Sorry, #{disk_size}MB is not enough for #{@appliance}, please give >= #{min_disk_size}MB"
        return false
      end

      @appliance_config.disk_size = disk_size
      return true
    end

  end
end