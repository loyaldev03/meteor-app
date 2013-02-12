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

# 1- do we need to update phoenix.product_sku = @campaign.product_sku ?/????? 
# 2- load_cancellations  
