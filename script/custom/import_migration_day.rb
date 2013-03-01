#!/bin/ruby

# run only once the migration day after other scripts.

require 'import_models'

@log = Logger.new('log/import_operations.log', 10, 1024000)
ActiveRecord::Base.logger = @log


def load_cancellations
  ActiveRecord::Base.connection.execute "delete from operations where club_id = #{CLUB} and operation_type = #{Settings.operation_types.cancel}"

  PhoenixMembership.where("status = 'lapsed'").find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |membership|
      begin
        @member = membership.member
        cancel_date = membership.cancel_date
        add_operation(cancel_date, 'Membership', membership.id, "Member canceled", Settings.operation_types.cancel, cancel_date, cancel_date) 
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
      end
    end
  end
end

def process_preferences
  phoenix.preferences.each do |key, value|
    pref = PhoenixMemberPreference.find_or_create_by_member_id_and_club_id_and_param(phoenix.id, phoenix.club_id, key)
    pref.value = value
    pref.save
  end
end

# 1- do we need to update phoenix.product_sku = @campaign.product_sku ?/????? 
# 2- load_cancellations  
# 3- process_preferences

