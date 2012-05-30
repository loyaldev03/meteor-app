module Wordpress
  class Sync < ActiveRecord::Observer
    observe :member

    def after_save(member)
      member.wordpress_member.save!
    end

    def after_destroy(member)
      member.wordpress_member.destroy!
    end
  end
end
