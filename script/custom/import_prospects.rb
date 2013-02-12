#!/bin/ruby

require 'import_models'

@log = Logger.new('log/import_prospects.log', 10, 1024000)
ActiveRecord::Base.logger = @log

ProspectProspect.where(" imported_at IS NULL and member_id IS NULL ").find_in_batches do |group|
  puts "cant #{group.count}"
  group.each do |prospect| 
    get_campaign_and_tom_id(prospect.campaign_id)
    if @tom_id.nil?
      puts "CDId #{member.campaign_id} does not exist or TOM is empty"
      next
    end
    tz = Time.now.utc
    @log.info "  * processing prospect ##{prospect.id}"
    begin
      new_prospect(prospect, @campaign, @tom_id)
      prospect.update_attribute :imported_at, Time.now.utc
      print "."
    rescue Exception => e
      @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      exit
      return
    end
    @log.info "    ... took #{Time.now.utc - tz} for prospect ##{prospect.id}"
  end
end

