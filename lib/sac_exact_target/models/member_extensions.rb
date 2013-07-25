module SacExactTarget
  module MemberExtensions
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def sync_members_to_exact_target
        index = 0
        base = Member.where(" exact_target_synced_status = 'not_synced' ")
        Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:sync_members_to_exact_target, processing #{base.count} members"
        base.find_in_batches do |group|
          group.each do |member|
            tz = Time.zone.now
            begin
              index = index+1
              Rails.logger.info "  *[#{index}] processing member ##{member.id}"
              member.marketing_tool_sync
            rescue Exception => e
              Airbrake.notify(:error_class => "Pardot::MemberSync", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect })
              Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
            end
            Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
          end
        end
      end
    end

    module InstanceMethods
      def exact_target_after_create_sync_to_remote_domain
        exact_target_sync_to_remote_domain unless exact_target_member.nil?
      end

      def exact_target_sync_to_remote_domain
        return if @skip_exact_target_sync
        time_elapsed = Benchmark.ms do
          exact_target_member.save!
        end
        logger.info "SacExactTarget::sync took #{time_elapsed}ms"
      rescue Timeout::Error => e
        raise e
      rescue Exception => e
        Auditory.report_issue("Member:sync", e, { :member => self.inspect })
        raise e
      end

      def unsubscribe
        time_elapsed = Benchmark.ms do
          exact_target_member.unsubscribe_subscriber!
        end
        logger.info "SacExactTarget::unsubscribe_subscriber took #{time_elapsed}ms"
      rescue Timeout::Error => e
        raise e
      rescue Exception => e
        Auditory.report_issue("Member:unsubscribe_subscriber", e, { :member => self.inspect })
        raise e
      end
        
      def exact_target_sync?
        self.club.exact_target_sync?
      end

      def exact_target_member
        @exact_target_member ||= if !self.exact_target_sync?
          nil
        else
          SacExactTarget::MemberModel.new self
        end
      end

      def skip_exact_target_sync!
        @skip_exact_target_sync = true
      end
    end
  end
end