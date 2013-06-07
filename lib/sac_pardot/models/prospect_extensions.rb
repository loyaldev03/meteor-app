module Pardot
  module ProspectExtensions
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      after_create :pardot_after_create_sync_to_remote_domain, :if => defined? Pardot::Prospect
      def pardot_after_create_sync_to_remote_domain
        pardot_sync_to_remote_domain unless pardot_prospect.nil?
      end
    end    
     
    module InstanceMethods
      def pardot_prospect
        @pardot_prospect ||= if !self.club.pardot_sync?
          nil
        else
          Pardot::Prospect.new self
        end
      end
    end

    def pardot_sync_to_remote_domain
      time_elapsed = Benchmark.ms do
        pardot_prospect.save! unless pardot_prospect.nil?
      end
      logger.info "Pardot::sync took #{time_elapsed}ms"
    rescue Exception => e
      Auditory.report_issue("Prospect:sync", e, { :prospect => self.inspect })
    end
    handle_asynchronously :pardot_sync_to_remote_domain

  end
end