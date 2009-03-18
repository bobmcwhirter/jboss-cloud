$: << 'lib/jboss-cloud-support/lib'

require 'jboss-cloud/image-builder'
require 'yaml'

jboss_cloud_info = YAML.load_file( 'jboss-cloud' )

JBossCloud::ImageBuilder.new(
  :name    => jboss_cloud_info['name'].to_s,
  :version => jboss_cloud_info['version'].to_s,
  :release => jboss_cloud_info['release'].to_s
)
