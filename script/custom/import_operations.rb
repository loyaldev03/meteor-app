#!/bin/ruby

require_relative 'import_models'

@log = Logger.new('import_members.log', 10, 1024000)
ActiveRecord::Base.logger = @log

def add_operation(operation_date, object, description, operation_type, created_at, updated_at, author = 999)
  # TODO: levantamos los Agents?
  current_agent = Agent.find_by_email('batch@xagax.com') if author == 999
  o = Operation.new :operation_date => operation_date, 
        :resource => object, :description => description, :operation_type => operation_type
  o.created_by_id = current_agent.id
  o.created_at = created_at
  o.updated_at = updated_at
  o.member = @member
  o.save!
end

def load_cancel 
  if @member.lapsed?
    add_operation(@member.cancel_date, @member, "Member canceled", Settings.operation_types.cancel, @member.cancel_date, @member.cancel_date)
  end
end
def load_save_the_sale
  CustomerServicesOperations.find(:all, :conditions => " contact_id = #{@member.visible_id} AND name like '%Edit Campaign%' ").each do |op|
    add_operation(op.operation_date, nil, op.name, Settings.operation_types.save_the_sale, op.created_on, op.updated_on, op.author_id)
  end
end
def load_recovery
  CustomerServicesOperations.find(:all, :conditions => " contact_id = #{@member.visible_id} AND name like '%Customer Services Reactivate%' ").each do |op|
    add_operation(op.operation_date, nil, op.name, Settings.operation_types.save_the_sale, op.created_on, op.updated_on, op.author_id)
    @member.increment!(:reactivation_times)
  end
end

PhoenixMember.find_in_batches do |group|
  group.each do |member|
    tz = Time.now
    begin
      @log.info "  * processing member ##{member.uuid}"
      @member = member
      load_cancel 
      load_save_the_sale
      load_recovery
    rescue Exception => e
      @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      exit
    end
    @log.info "    ... took #{Time.now - tz} for member ##{member.uuid}"
  end
  sleep(5) # Make sure it doesn't get too crowded in there!
end

