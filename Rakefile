require 'jboss-cloud-config'

$: << 'lib/jboss-cloud-support/lib'

require 'jboss-cloud/image-builder'

JBossCloud::ImageBuilder.setup(
  :name    => JBossCloudConfig.config.name,
  :version => JBossCloudConfig.config.version,
  :release => JBossCloudConfig.config.release
)
