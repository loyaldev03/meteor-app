module Drupal
  module MemberExtensions
    def self.included(base)
      # base.extend ClassMethods
      base.send :include, InstanceMethods
      base.scope :synced, lambda { |bool=true|
        bool ?
          base.where('last_synced_at > updated_at') :
          base.where('last_synced_at IS NULL OR last_synced_at < updated_at')
      }
    end

    module InstanceMethods
      def drupal_member
        @drupal_member ||= Drupal::Member.new self
      end

      def synced?
        self.last_synced_at && self.last_synced_at > self.updated_at
      end
    end
  end
end