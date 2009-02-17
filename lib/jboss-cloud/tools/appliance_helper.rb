module JBossCloud
  class ApplianceHelper

    # returns a new object with default values
    def self.create_appliance_config_stub
      config = ApplianceConfig.new

      config.os_name = "fedora"
      config.os_version = 10
      config.vcpu = 1
      config.mem_size = 1024
      config.disk_size = 2048
      config.network_name = "NAT"

      config
    end

  end
end
