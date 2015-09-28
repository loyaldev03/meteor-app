require 'auditory'
require 'exception_notification'
SacPlatform::Application.config.middleware.use ExceptionNotifier if ['production', 'staging', 'prototype'].include?(Rails.env)
require 'axlsx'
require "exceptions"

class String
  def to_bool
    return true if self == true || self =~ (/(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/(false|f|no|n|0)$/i)
    Rails.logger.error "invalid value for Boolean: \"#{self}\""
    return false
  end
end

# require 'bureaucrat'
# require 'bureaucrat/quickfields'
# require 'bureaucrat/form'
