module SacExactTarget
  module MemberExtensions
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def sync_members_to_exact_target
        base = User.where("need_sync_to_marketing_client = 1 AND club_id in (?)", Club.exact_target_related.pluck(:id))
        Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:sync_members_to_exact_target, processing #{base.count} members"
        base.find_in_batches do |group|
          group.each_with_index do |member, index|
            tz = Time.zone.now
            begin
              Rails.logger.info "  *[#{index+1}] processing member ##{member.id}"
              member.marketing_tool_exact_target_sync_without_delay
            rescue Exception => e
              Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
            end
            Rails.logger.info "    ... took #{Time.zone.now - tz}seconds for member ##{member.id}"
          end
        end
      end
    end

    module InstanceMethods
      def exact_target_after_create_sync_to_remote_domain
        exact_target_sync_to_remote_domain! if exact_target_member
      end

      def exact_target_sync_to_remote_domain!
        return if @skip_exact_target_sync
        time_elapsed = Benchmark.ms do
          exact_target_member.save!
        end
        logger.info "SacExactTarget::sync took #{time_elapsed}ms"
      rescue Exception => e
        SacExactTarget::report_error("Member:ExactTargetsync", e, self)
        raise e
      end

      def marketing_tool_exact_target_sync
        exact_target_after_create_sync_to_remote_domain
      end
      handle_asynchronously :marketing_tool_exact_target_sync, :queue => :exact_target_sync, priority: 30

      def exact_target_subscribe
        exact_target_member.subscribe! if exact_target_member
      end
      handle_asynchronously :exact_target_subscribe, :queue => :exact_target_sync, priority: 30

      def exact_target_unsubscribe
        time_elapsed = Benchmark.ms do
          exact_target_after_create_sync_to_remote_domain
          exact_target_member.unsubscribe!
        end
        logger.info "SacExactTarget::unsubscribe_subscriber took #{time_elapsed}ms"
      rescue Exception => e
        SacExactTarget::report_error("Member:unsubscribe_subscriber", e, self)
        raise e
      end
      handle_asynchronously :exact_target_unsubscribe, :queue => :exact_target_sync, priority: 30

      def exact_target_sync?
        self.club.exact_target_sync?
      end

      def exact_target_member
        return @exact_target_member unless @exact_target_member.nil?
        if not self.club.exact_target_client?
          false
        elsif club.exact_target_sync?
          SacExactTarget.config_integration(self.club.marketing_tool_attributes["et_username"], self.club.marketing_tool_attributes["et_password"], self.club.marketing_tool_attributes["et_endpoint"])
          @exact_target_member ||= if !self.exact_target_sync?
            false
          else
            SacExactTarget::MemberModel.new self
          end
        else
          SacExactTarget::report_error("Member:exact_target_member", 'Exact Target not configured correctly', self)
          false
        end
      end

      def skip_exact_target_sync!
        @skip_exact_target_sync = true
      end
    end
  end
end