# encoding: utf-8
require 'test_helper'

class MemberTest < ActiveSupport::TestCase

  setup do
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway)
    @sd_strategy = FactoryGirl.create(:soft_decline_strategy)

  end

  test "Should create a member" do
    member = FactoryGirl.build(:member)
    assert !member.save, member.errors.inspect
    member.club =  @terms_of_membership_with_gateway.club
    Delayed::Worker.delay_jobs = true
    assert_difference('Delayed::Job.count', 1, 'should ceate job for #desnormalize_preferences') do
      assert member.save, "member cant be save #{member.errors.inspect}"
    end
    Delayed::Worker.delay_jobs = false
  end

  test "Should not create a member without first name" do
    member = FactoryGirl.build(:member, :first_name => nil)
    assert !member.save
  end

  test "Should not create a member without last name" do
    member = FactoryGirl.build(:member, :last_name => nil)
    assert !member.save
  end

  test "Should create a member without gender" do
    member = FactoryGirl.build(:member, :gender => nil)
    assert !member.save
  end

  test "Should create a member without type_of_phone_number" do
    member = FactoryGirl.build(:member, :type_of_phone_number => nil)
    assert !member.save
  end

  test "Member should not be billed if it is not active or provisional" do
    member = create_active_member(@terms_of_membership_with_gateway, :lapsed_member)
    answer = member.bill_membership
    assert !(answer[:code] == Settings.error_codes.success), answer[:message]
  end

  test "Member should not be billed if no credit card is on file." do
    member = create_active_member(@terms_of_membership_with_gateway, :provisional_member)
    answer = member.bill_membership
    assert (answer[:code] != Settings.error_codes.success), answer[:message]
  end

  test "Insfufficient funds hard decline" do
    active_member = create_active_member(@terms_of_membership_with_gateway)
    answer = active_member.bill_membership
    assert (answer[:code] == Settings.error_codes.success), answer[:message]
  end

  test "Monthly member should be billed if it is active or provisional" do
    assert_difference('Operation.count', 4) do
      member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc)
      prev_bill_date = member.next_retry_bill_date
      answer = member.bill_membership
      member.reload
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      assert_equal member.quota, 1, "quota is #{member.quota} should be 1"
      assert_equal member.recycled_times, 0, "recycled_times is #{member.recycled_times} should be 0"
      assert_equal member.bill_date, member.next_retry_bill_date, "bill_date is #{member.bill_date} should be #{member.next_retry_bill_date}"
      assert_equal member.next_retry_bill_date, (prev_bill_date + 1.month), "next_retry_bill_date is #{member.next_retry_bill_date} should be #{(prev_bill_date + 1.month)}"
    end
  end

  test "Should not save with an invalid email" do
    member = FactoryGirl.build(:member, :email => 'testing.com.ar')
    member.valid?
    assert_not_nil member.errors, member.errors.full_messages.inspect
  end

  test "Should not be two members with the same email within the same club" do
    member = FactoryGirl.build(:member)
    member.club =  @terms_of_membership_with_gateway.club
    member.save
    member_two = FactoryGirl.build(:member)
    member_two.club =  @terms_of_membership_with_gateway.club
    member_two.email = member.email
    member_two.valid?
    assert_not_nil member_two, member_two.errors.full_messages.inspect
  end

  test "Should let save two members with the same email in differents clubs" do
    member = FactoryGirl.build(:member, email: 'testing@xagax.com', club: @terms_of_membership_with_gateway.club)
    member.club_id = 1
    member.save
    member_two = FactoryGirl.build(:member, email: 'testing@xagax.com', club: @terms_of_membership_with_gateway.club)
    member_two.club_id = 14
    assert member_two.save, "member cant be save #{member_two.errors.inspect}"
  end

  test "active member cant be recovered" do
    member = create_active_member(@terms_of_membership_with_gateway)
    tom_dup = FactoryGirl.create(:terms_of_membership_with_gateway)
    
    answer = member.recover(tom_dup)
    assert answer[:code] == Settings.error_codes.member_already_active, answer[:message]
  end

  test "Lapsed member with reactivation_times = 5 cant be recovered" do
    member = create_active_member(@terms_of_membership_with_gateway)
    member.set_as_canceled!
    member.update_attribute( :reactivation_times, 5 )
    tom_dup = FactoryGirl.create(:terms_of_membership_with_gateway)

    answer = member.recover(tom_dup)
    assert answer[:code] == Settings.error_codes.cant_recover_member, answer[:message]
  end

  test "Lapsed member can be recovered" do
    assert_difference('Fulfillment.count',Club::DEFAULT_PRODUCT.count) do
      member = create_active_member(@terms_of_membership_with_gateway, :lapsed_member)
      answer = member.recover(@terms_of_membership_with_gateway)
      assert answer[:code] == Settings.error_codes.success, answer[:message]
      assert_equal 'provisional', member.status, "Status was not updated."
      assert_equal 1, member.reactivation_times, "Reactivation_times was not updated."
    end
  end

  test "Lapsed member can be recovered unless it needs approval" do
    @tom_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval)
    member = create_active_member(@tom_approval, :lapsed_member)
    answer = member.recover(@tom_approval)
    member.reload
    assert answer[:code] == Settings.error_codes.success, answer[:message]
    assert_equal 'applied', member.status
    assert_equal 1, member.reactivation_times
  end

  test "Recovered member in applied status is rejected. Reactivation times should stay at 0." do
    @tom_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval)
    member = create_active_member(@tom_approval, :lapsed_member)
    answer = member.recover(@tom_approval)
    member.reload
    assert answer[:code] == Settings.error_codes.success, answer[:message]
    assert_equal 'applied', member.status
    assert_equal 1, member.reactivation_times
    member.set_as_canceled
    member.reload
    assert_equal 'lapsed', member.status
    assert_equal 0, member.reactivation_times
  end


  test "Should not let create a member with a wrong format zip" do
    ['12345-1234', '12345'].each {|zip| zip
      member = FactoryGirl.build(:member, zip: zip, club: @terms_of_membership_with_gateway.club)
      assert member.save, "Member cant be save #{member.errors.inspect}"
    }    
    ['1234-1234', '12345-123', '1234'].each {|zip| zip
      member = FactoryGirl.build(:member, zip: zip, club: @terms_of_membership_with_gateway.club)
      assert !member.save, "Member cant be save #{member.errors.inspect}"
    }        
  end

  #Check cancel email
  test "If member is rejected, when recovering it should increment reactivation_times" do
    member = create_active_member(@terms_of_membership_with_gateway, :applied_member)
    member.set_as_canceled!
    answer = member.recover(@terms_of_membership_with_gateway)
    member.reload
    assert answer[:code] == Settings.error_codes.success, answer[:message]
    assert_equal 'provisional', member.status
    assert_equal 1, member.reactivation_times
  end

  test "Should reset club_cash when member is canceled" do
    member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc, nil, { :club_cash_amount => 200 })
    member.set_as_canceled
    assert_equal 0, member.club_cash_amount, "The member is #{member.status} with #{member.club_cash_amount}"
  end

  test "Canceled member should have cancel date set " do
    member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc)
    cancel_date = member.cancel_date
    member.cancel! Time.zone.now, "Cancel from Unit Test"
    m = Member.find member.uuid
    assert_not_nil m.cancel_date 
    assert_nil cancel_date
  end

  test "Member should be saved with first_name and last_name with numbers or acents." do
    member = FactoryGirl.build(:member)
    assert !member.save, member.errors.inspect
    member.club =  @terms_of_membership_with_gateway.club
    member.first_name = 'Billy 3ro'
    member.last_name = 'Sáenz'
    assert member.save, "member cant be save #{member.errors.inspect}"
  end

  test "Should not deduct more club_cash than the member has" do
    member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc, nil, { :club_cash_amount => 200 })
    member.add_club_cash(-300)
    assert_equal 200, member.club_cash_amount, "The member is #{member.status} with $#{member.club_cash_amount}"
  end

  test "if active member is blacklisted, should have cancel date set " do
    member = create_active_member(@terms_of_membership_with_gateway)
    cancel_date = member.cancel_date
    # 2 operations : cancel and blacklist
    assert_difference('Operation.count', 4) do
      member.blacklist(nil, "Test")
    end
    m = Member.find member.uuid
    assert_not_nil m.cancel_date 
    assert_nil cancel_date
    assert_equal m.blacklisted, true
  end

  test "if lapsed member is blacklisted, it should not be canceled again" do
    member = create_active_member(@terms_of_membership_with_gateway, :lapsed_member, nil, { reactivation_times: 5 })
    cancel_date = member.cancel_date
    assert_difference('Operation.count', 1) do
      member.blacklist(nil, "Test")
    end
    m = Member.find member.uuid
    assert_not_nil m.cancel_date 
    assert_equal m.cancel_date.to_date, cancel_date.to_date
    assert_equal m.blacklisted, true
  end

  test "If member's email contains '@noemail.com' it should not send emails." do
    member = create_active_member(@terms_of_membership_with_gateway, :lapsed_member, nil, { email: "testing@noemail.com" })
    assert_difference('Operation.count', 1) do
      Communication.deliver!(:active, member)
    end
    assert_equal member.operations.last.description, "The email contains '@noemail.com' which is an empty email. The email won't be sent."
  end

  test "show dates according to club timezones" do
    saved_member = create_active_member(@terms_of_membership_with_gateway)
    saved_member.member_since_date = "Wed, 02 May 2012 19:10:51 UTC 00:00"
    saved_member.current_membership.join_date = "Wed, 03 May 2012 13:10:51 UTC 00:00"
    saved_member.next_retry_bill_date = "Wed, 03 May 2012 00:10:51 UTC 00:00"
    Time.zone = "Eastern Time (US & Canada)"
    assert_equal I18n.l(Time.zone.at(saved_member.member_since_date)), "05/02/2012"
    assert_equal I18n.l(Time.zone.at(saved_member.next_retry_bill_date)), "05/02/2012"
    assert_equal I18n.l(Time.zone.at(saved_member.current_membership.join_date)), "05/03/2012"
    Time.zone = "Ekaterinburg"
    assert_equal I18n.l(Time.zone.at(saved_member.member_since_date)), "05/03/2012"
    assert_equal I18n.l(Time.zone.at(saved_member.next_retry_bill_date)), "05/03/2012"
    assert_equal I18n.l(Time.zone.at(saved_member.current_membership.join_date)), "05/03/2012"
  end


  test "Recycle credit card with billing success" do
    @club = @terms_of_membership_with_gateway.club
    member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc)
    original_year = (Time.zone.now - 2.years).year
    member.credit_cards.each { |s| s.update_attribute :expire_year , original_year } # force to be expired!
    member.reload
    assert_difference('CreditCard.count', 0) do
      assert_difference('Operation.count', 4) do
        assert_difference('Transaction.count') do
          assert_equal member.recycled_times, 0
          answer = member.bill_membership
          member.reload
          assert_equal answer[:code], Settings.error_codes.success
          assert_equal original_year, member.transactions.last.expire_year
          assert_equal member.recycled_times, 0
          assert_equal member.credit_cards.count, 1 # only one credit card
          assert_equal member.credit_cards.first.expire_year, original_year # expire_year should not be changed.
        end
      end
    end
  end

  test "Recycle credit card twice" do
    @club = @terms_of_membership_with_gateway.club
    member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc)
    active_merchant_stubs_store
    active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false)
    original_year = 2000
    member.credit_cards.each { |s| s.update_attribute :expire_year , original_year } # force to be expired!
    member.reload
    assert_difference('CreditCard.count', 0) do
      assert_difference('Operation.count', 2) do
        assert_difference('Transaction.count') do
          assert_equal member.recycled_times, 0
          answer = member.bill_membership
          member.reload
          assert_equal answer[:code], @sd_strategy.response_code
          assert_equal member.recycled_times, 1
          assert_equal member.credit_cards.count, 1 # only one credit card
          assert_equal member.credit_cards.first.expire_year, original_year # original expire year should not be touch, because we need it to recycle
        end
      end
    end

    # im sorry to add this sleep. But if I dont, the member.transactions.last does not work always. why?
    # because the created_at of both transactions has the same value!!!
    sleep(1)
    assert_difference('CreditCard.count', 0) do
      assert_difference('Operation.count', 2) do
        assert_difference('Transaction.count') do
          answer = member.bill_membership
          member.reload
          assert_equal answer[:code], @sd_strategy.response_code
          assert_equal member.recycled_times, 2
          assert_equal member.credit_cards.count, 1 # only one credit card
          assert_equal member.credit_cards.first.expire_year, original_year # original expire year should not be touch, because we need it to recycle
        end
      end
    end
  end

  test "Billing for renewal amount" do
    @club = @terms_of_membership_with_gateway.club
    member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc)

    assert_difference('Operation.count', 4) do
      prev_bill_date = member.next_retry_bill_date
      answer = member.bill_membership
      member.reload
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      assert_equal member.quota, 1, "quota is #{member.quota} should be 1"
      assert_equal member.recycled_times, 0, "recycled_times is #{member.recycled_times} should be 0"
      assert_equal member.bill_date, member.next_retry_bill_date, "bill_date is #{member.bill_date} should be #{member.next_retry_bill_date}"
      assert_equal member.next_retry_bill_date, (prev_bill_date + 1.month), "next_retry_bill_date is #{member.next_retry_bill_date} should be #{(prev_bill_date + 1.month)}"
    end


    Timecop.freeze(Time.zone.now + 1.month) do
      prev_bill_date = member.next_retry_bill_date
      answer = member.bill_membership
      member.reload
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      assert_equal member.quota, 2, "quota is #{member.quota} should be 1"
      assert_equal member.recycled_times, 0, "recycled_times is #{member.recycled_times} should be 0"
      assert_equal member.bill_date, member.next_retry_bill_date, "bill_date is #{member.bill_date} should be #{member.next_retry_bill_date}"
      assert_equal member.next_retry_bill_date, (prev_bill_date + 1.month), "next_retry_bill_date is #{member.next_retry_bill_date} should be #{(prev_bill_date + 1.month)}"
    end
  end

  # Prevent club to be billed
  test "Member should not be billed if club's billing_enable is set as false" do
    @club = @terms_of_membership_with_gateway.club
    @club.update_attribute(:billing_enable, false)
    @member = create_active_member(@terms_of_membership_with_gateway, :provisional_member)

    @member.current_membership.update_attribute(:quota, 2)
    quota_before = @member.quota
    next_bill_date_before = @member.next_retry_bill_date
    bill_date_before = @member.bill_date

    assert_difference('Operation.count', 0) do
      assert_difference('Transaction.count', 0) do
        Member.bill_all_members_up_today
      end
    end
    @member.reload
    assert_equal(quota_before,@member.quota)
    assert_equal(next_bill_date_before,@member.next_retry_bill_date)
    assert_equal(bill_date_before,@member.bill_date)
  end

  # Prevent club to be billed
  test "Member should be billed if club's billing_enable is set as true" do
    @club = @terms_of_membership_with_gateway.club
    @member = create_active_member(@terms_of_membership_with_gateway, :provisional_member)

    @member.current_membership.update_attribute(:quota, 2)
    quota_before = @member.quota
    next_bill_date_before = @member.next_retry_bill_date
    bill_date_before = @member.bill_date

    assert_difference('Operation.count', 0) do
      assert_difference('Transaction.count', 0) do
        Member.bill_all_members_up_today
      end
    end
    @member.reload
    assert_equal(quota_before,@member.quota)
    assert_equal(next_bill_date_before,@member.next_retry_bill_date)
    assert_equal(bill_date_before,@member.bill_date)
  end

  test "Change member from Lapsed status to active status" do
    @club = @terms_of_membership_with_gateway.club
    @saved_member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc)
    @saved_member.set_as_canceled

    @saved_member.recover(@terms_of_membership_with_gateway)

    next_bill_date = @saved_member.bill_date + 1.month

    Timecop.freeze( @saved_member.bill_date ) do
      Member.bill_all_members_up_today
      @saved_member.reload

      assert_equal(@saved_member.current_membership.status, "active")
      assert_equal(I18n.l(@saved_member.next_retry_bill_date, :format => :only_date), I18n.l(next_bill_date, :format => :only_date))
    end
  end

end