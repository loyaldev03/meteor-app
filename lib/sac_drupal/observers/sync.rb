module Drupal
  class Sync < ActiveRecord::Observer
    observe :member

    def after_save(member)
      member.drupal_member.save!
    end

    def after_destroy(member)
      member.drupal_member.destroy!
    end
  end
end