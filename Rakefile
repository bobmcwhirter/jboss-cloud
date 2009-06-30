$: << 'lib/jboss-cloud-support/lib'

require 'jboss-cloud/validator/errors'
require 'jboss-cloud/image-builder'
require 'jboss-cloud/defaults'

$stderr.reopen("/dev/null")

module Rake
  class Task
    alias_method :execute_original, :execute

    def execute( args=nil )
      begin
        execute_original( args )
      rescue => e
        JBossCloud::LOG.fatal e
        JBossCloud::LOG.fatal e.message
        abort
      end
    end
  end
end

begin
  JBossCloud::LOG.debug "Running new Rake session..."
  
  JBossCloud::ImageBuilder.new
rescue JBossCloud::ValidationError => e
  JBossCloud::LOG.fatal "ValidationError: #{e.message}."
  abort
rescue => e
  JBossCloud::LOG.fatal e
  JBossCloud::LOG.fatal "Aborting: #{e.message}. See previous errors for more information."
  abort
end
