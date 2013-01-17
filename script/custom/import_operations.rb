#!/bin/ruby

require 'import_models'

@log = Logger.new('log/import_operations.log', 10, 1024000)
ActiveRecord::Base.logger = @log

def load_save_the_sales
  CustomerServicesOperations.where(" name like '%Edit Campaign%' and imported_at IS NULL " +
    (USE_MEMBER_LIST ? " and contact_id IN (#{PhoenixMember.find_all_by_club_id(CLUB).map(&:visible_id).join(',')}) " : "")
    ).find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |op|
      begin
        @member = PhoenixMember.find_by_visible_id_and_club_id  op.contact_id, CLUB
        unless @member.nil?
          @log.info "  * processing CS operation ##{op.id}"
          add_operation(op.operation_date, nil, nil, op.name, Settings.operation_types.save_the_sale, op.created_on, op.updated_on, op.author_id)
          op.update_attribute :imported_at, Time.now.utc
          print "."
        end
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
      end
    end
  end
end

def load_reactivations
  CustomerServicesOperations.where(" name like '%Customer Services Reactivate%' and imported_at IS NULL " +
    (USE_MEMBER_LIST ? " and contact_id IN (#{PhoenixMember.find_all_by_club_id(CLUB).map(&:visible_id).join(',')}) " : "")
    ).find_in_batches do |group|
    puts "cant #{group.count}"
    group.each do |op|
      begin
        @member = PhoenixMember.find_by_visible_id_and_club_id  op.contact_id, CLUB
        unless @member.nil?
          @log.info "  * processing CS operation ##{op.id}"
          add_operation(op.operation_date, nil, nil, op.name, Settings.operation_types.recovery, op.created_on, op.updated_on, op.author_id)
          @member.increment!(:reactivation_times)
          op.update_attribute :imported_at, Time.now.utc
          print "."
        end
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
      end
    end
  end
end

load_save_the_sales
load_reactivations
