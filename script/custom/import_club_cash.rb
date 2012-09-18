#!/bin/ruby

require 'import_models'

@log = Logger.new('import_club_cash.log', 10, 1024000)
ActiveRecord::Base.logger = @log

# https://redmine.xagax.com/issues/19806

today = Date.today.year

ActiveRecord::Base.connection.execute "update members set club_cash_amount = 0, club_cash_expire_date = NULL where club_id = #{CLUB}"

PhoenixMember.where(" status IN ('provisional', 'active') ").find_in_batches do |group|
  puts "cant #{group.count}"
  group.each do |member| 
    tz = Time.now.utc
    @log.info "  * processing member ##{member.id}"
    begin
      member.club_cash_expire_date = member.join_date + (today.year - member.join_date.year + 1).years

      tom = PhoenixTermsOfMembership.find_by_id member.terms_of_membership_id
      if member.member_group_type_id
        member.club_cash_amount = 200
      elsif tom.installment_type == '1.year'
        member.club_cash_amount = tom.club_cash_amount
      else
        # monthly
        member.club_cash_amount = tom.club_cash_amount * (member % 12)
      end

      cct = PhoenixClubCashTransaction.find_or_create_by_member_id member.uuid
      cct.amount = member.club_cash_amount
      cct.description = "Imported club cash"
      cct.save!
      member.save

      print "."
    rescue Exception => e
      @log.info "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      puts "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
      raise ActiveRecord::Rollback
    end
    @log.info "    ... took #{Time.now.utc - tz} for member ##{member.id}"
  end
end

