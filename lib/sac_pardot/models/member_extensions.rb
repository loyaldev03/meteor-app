module Pardot
  module MemberExtensions
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def sync_members_to_pardot
        index = 0
        base = User.where("date(updated_at) >= ? ", Time.zone.now.yesterday.to_date).limit(2000)
        Rails.logger.info " *** [#{I18n.l(Time.zone.now, :format =>:dashed)}] Starting members:sync_members_to_pardot, processing #{base.count} members"
        base.each do |member|
          tz = Time.zone.now
          begin
            index = index+1
            Rails.logger.info "  *[#{index}] processing member ##{member.id}"
            member.sync_to_pardot unless member.pardot_member.nil?
          rescue Exception => e
            Airbrake.notify(:error_class => "Pardot::MemberSync", :error_message => "#{e.to_s}\n\n#{$@[0..9] * "\n\t"}", :parameters => { :member => member.inspect })
            Rails.logger.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
          end
          Rails.logger.info "    ... took #{Time.zone.now - tz} for member ##{member.id}"
        end
      end
    end     
    
    module InstanceMethods
      def sync_to_pardot(options = {})
        time_elapsed = Benchmark.ms do
          pardot_member.save!(options) unless pardot_member.nil?
        end
        logger.info "Pardot::sync took #{time_elapsed}ms"
      rescue Exception => e
        Airbrake.notify(:error_class => "Pardot:sync", :error_message => e, :parameters => { :member => self.inspect })
      end
      
      def pardot_sync?
        self.club.pardot_sync?
      end

      def pardot_member
        @pardot_member ||= if !self.pardot_sync?
          nil
        else
          Pardot::Member.new self
        end
      end

      def skip_pardot_sync!
        @skip_pardot_sync = true
      end
    end
  end
end