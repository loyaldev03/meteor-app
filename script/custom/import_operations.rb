#!/bin/ruby

require_relative 'import_models'


def load_save_the_sales
  CustomerServicesOperations.where(" name like '%Edit Campaign%' and imported_at IS NULL ").find_in_batches do |group|
    group.each do |op|
      tz = Time.now
      begin
        @log.info "  * processing CS operation ##{op.id}"
        @member = PhoenixMember.find_by_visible_id_and_club_id  op.contact_id, CLUB
        if @member.nil?
          @log.info "  * Member id ##{op.contact_id} not found "
        else
          add_operation(op.operation_date, nil, op.name, Settings.operation_types.save_the_sale, op.created_on, op.updated_on, op.author_id)
          op.update_attribute :imported_at, Time.zone.now
        end
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
      end
      @log.info "    ... took #{Time.now - tz} for CS operation ##{op.id}"
    end
  end
end

def load_reactivations
  CustomerServicesOperations.where(" name like '%Customer Services Reactivate%' and imported_at IS NULL ").find_in_batches do |group|
    group.each do |op|
      tz = Time.now
      begin
        @log.info "  * processing CS operation ##{op.id}"
        @member = PhoenixMember.find_by_visible_id_and_club_id  op.contact_id, CLUB
        if @member.nil?
          @log.info "  * Member id ##{op.contact_id} not found "
        else
          add_operation(op.operation_date, nil, op.name, Settings.operation_types.recovery, op.created_on, op.updated_on, op.author_id)
          @member.increment!(:reactivation_times)
          op.update_attribute :imported_at, Time.zone.now
        end
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
      end
      @log.info "    ... took #{Time.now - tz} for CS operation ##{op.id}"
    end
  end
end


load_save_the_sales
load_reactivations
