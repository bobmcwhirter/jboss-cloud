class JBossCloudConfig
  @@config = nil

  def initialize(name, version, release)
    @name    = name
    @version = version
    @release = release
  end

  def self.config
    if (@@config == nil)
      @@config = JBossCloudConfig.new(
        "JBoss-Cloud",
        "1.0.0.Beta3",
        "1"
      )
    end

    @@config
  end

  attr_reader :name
  attr_reader :version
  attr_reader :release
end

