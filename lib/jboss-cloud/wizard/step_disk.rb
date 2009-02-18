require 'jboss-cloud/wizard/step'

module JBossCloudWizard
  class StepDisk < Step
    def initialize(config)
      @config = config
    end

    def ask
      ask_for_disk
    end

    def default_disk_size(appliance)
      if appliance == "meta-appliance"
        disk_size = 10240
      else
        disk_size = 2048
      end

      disk_size
    end

    def ask_for_disk

      disk_size = default_disk_size(@config.name)

      print "\n#{banner} How big should be the disk (in MB)? [#{disk_size}] "

      disk_size = gets.chomp

      ask_for_disk unless valid_disk_size?( disk_size )
    end

    def valid_disk_size?( disk_size )
      if (disk_size.length == 0)
        disk_size = default_disk_size(@config.name)
      end

      if disk_size.to_i == 0
        puts "Sorry, #{disk_size} is not a valid value" unless disk_size.length == 0
        return false
      end

      min_disk_size = default_disk_size(@config.name)

      if (disk_size.to_i % 1024 > 0)
        puts "Disk size should be multiplicity of 1024MB"
        return false
      end

      if (disk_size.to_i < min_disk_size)
        puts "Sorry, #{disk_size}MB is not enough for #{@config.name}, please give >= #{min_disk_size}MB"
        return false
      end

      @config.disk_size = disk_size
      return true
    end

  end
end