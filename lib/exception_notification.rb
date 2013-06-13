require 'active_support/deprecation'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/string/inflections'

class ExceptionNotifier

  class UndefinedNotifierError < StandardError; end

  class << self
    @@notifiers = {}
    @@ignored_exceptions = ['ActiveRecord::RecordNotFound', 'AbstractController::ActionNotFound', 'ActionController::RoutingError']

    def notify_exception(exception, options={})
      return if ignored_exception?(options[:ignore_exceptions], exception)
      env = options[:env]
      Auditory.report_issue("#{env['action_controller.instance']}", exception, { :request => ActionDispatch::Request.new(env), :backtrace => exception.backtrace })
    end

    def ignored_exceptions
      @@ignored_exceptions
    end

    private
      def ignored_exception?(ignore_array, exception)
        (ignored_exceptions + Array.wrap(ignore_array)).map(&:to_s).include?(exception.class.name)
      end
  end

  def initialize(app, options = {})
    @app = app
    @options = {}
    @options[:ignore_crawlers]    = options.delete(:ignore_crawlers) || []
    @options[:ignore_if]          = options.delete(:ignore_if) || lambda { |env, e| false }
    Rails.logger.error "hola"
  end

  def call(env)
    @app.call(env)
    Rails.logger.error "por aca pase"
  rescue Exception => exception
    options = @options.dup

    unless from_crawler(options[:ignore_crawlers], env['HTTP_USER_AGENT']) ||
           conditionally_ignored(options[:ignore_if], env, exception)
      ExceptionNotifier.notify_exception(exception, options.reverse_merge(:env => env))
      env['exception_notifier.delivered'] = true
    end

    raise exception
  end

  private

  def from_crawler(ignore_array, agent)
    ignore_array.each do |crawler|
      return true if (agent =~ Regexp.new(crawler))
    end unless ignore_array.blank?
    false
  end

  def conditionally_ignored(ignore_proc, env, exception)
    ignore_proc.call(env, exception)
  rescue Exception
    false
  end

end
