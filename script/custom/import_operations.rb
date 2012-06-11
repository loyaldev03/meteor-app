#!/bin/ruby

require_relative 'import_models'


def add_operation(operation_date, object, description, operation_type, created_at, updated_at, author = 999)
  o = PhoenixOperation.new :operation_date => operation_date, :description => description, :operation_type => operation_type
  o.created_by_id = get_agent(author)
  o.created_at = created_at
  if object.nil?
    o.resource_type = nil
    # o.resource_id = 0
  end
  o.updated_at = updated_at
  o.member_id = @member.uuid
  o.save!
end

def load_cancellations
  PhoenixMember.where("status = 'lapsed'").find_in_batches do |group|
    group.each do |member|
      tz = Time.now
      begin
        @log.info "  * processing member ##{member.uuid}"
        @member = member
        add_operation(@member.cancel_date, @member, "Member canceled", Settings.operation_types.cancel, @member.cancel_date, @member.cancel_date) 
      rescue Exception => e
        @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
        exit
      end
      @log.info "    ... took #{Time.now - tz} for member ##{member.uuid}"
    end
  end
end

def load_save_the_sales
  CustomerServicesOperations.where(" name like '%Edit Campaign%' ").find_in_batches do |group|
    group.each do |op|
      tz = Time.now
      begin
        @log.info "  * processing CS operation ##{op.id}"
        @member = PhoenixMember.find_by_visible_id_and_club_id  op.contact_id, CLUB
        if @member.nil?
          @log.info "  * Member id ##{op.contact_id} not found "
        else
          add_operation(op.operation_date, nil, op.name, Settings.operation_types.save_the_sale, op.created_on, op.updated_on, op.author_id)
          op.destroy
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
  CustomerServicesOperations.where(" name like '%Customer Services Reactivate%' ").find_in_batches do |group|
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
          op.destroy
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

load_cancellations
load_save_the_sales
load_reactivations
