# encoding: utf-8
require 'test_helper'

class MemberTest < ActiveSupport::TestCase

  setup do
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner
    Time.zone = @club.time_zone

    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @wordpress_terms_of_membership = FactoryGirl.create :wordpress_terms_of_membership_with_gateway, :club_id => @club.id
    @sd_strategy = FactoryGirl.create(:soft_decline_strategy)
  end

  test "Should create a member" do
    member = FactoryGirl.build(:member)
    assert !member.save, member.errors.inspect
    member.club = @terms_of_membership_with_gateway.club
    Delayed::Worker.delay_jobs = true
    assert_difference('Delayed::Job.count', 3, 'should create job for #desnormalize_preferences and mkt tool sync') do
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
    assert_difference('Operation.count', 3) do
      member = create_active_member(@wordpress_terms_of_membership, :provisional_member_with_cc)
      prev_bill_date = member.next_retry_bill_date
      answer = member.bill_membership
      member.reload
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      assert_equal member.recycled_times, 0, "recycled_times is #{member.recycled_times} should be 0"
      assert_equal member.bill_date, member.next_retry_bill_date, "bill_date is #{member.bill_date} should be #{member.next_retry_bill_date}"
      assert_equal I18n.l(member.next_retry_bill_date, :format => :only_date), I18n.l((prev_bill_date + member.terms_of_membership.installment_period.days), :format => :only_date), "next_retry_bill_date is #{member.next_retry_bill_date} should be #{(prev_bill_date + 1.month)}"
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
    @second_club = FactoryGirl.create(:simple_club_with_gateway)

    member = FactoryGirl.build(:member, email: 'testing@xagax.com', club: @terms_of_membership_with_gateway.club)
    member.club_id = 1
    member.save
    member_two = FactoryGirl.build(:member, email: 'testing@xagax.com', club: @second_club)
    assert member_two.save, "member cant be save #{member_two.errors.inspect}"
  end

  test "active member cant be recovered" do
    member = create_active_member(@terms_of_membership_with_gateway)
    tom_dup = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    
    answer = member.recover(tom_dup)
    assert answer[:code] == Settings.error_codes.member_already_active, answer[:message]
  end

  test "Lapsed member with reactivation_times = 5 cant be recovered" do
    member = create_active_member(@terms_of_membership_with_gateway)
    member.set_as_canceled!
    member.update_attribute( :reactivation_times, 5 )
    tom_dup = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)

    answer = member.recover(tom_dup)
    assert answer[:code] == Settings.error_codes.cant_recover_member, answer[:message]
  end

  test "Lapsed member can be recovered" do
    assert_difference('Fulfillment.count',Club::DEFAULT_PRODUCT.count) do
      member = create_active_member(@terms_of_membership_with_gateway, :lapsed_member)
      old_membership_id = member.current_membership_id 
      answer = member.recover(@terms_of_membership_with_gateway)
      assert answer[:code] == Settings.error_codes.success, answer[:message]
      assert_equal 'provisional', member.status, "Status was not updated."
      assert_equal 1, member.reactivation_times, "Reactivation_times was not updated."
      assert_equal member.current_membership.parent_membership_id, nil
    end
  end

  # When enrolling/recovering a member should send approval email as DJ
  test "Lapsed member can be recovered unless it needs approval" do
    @tom_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    member = create_active_member(@tom_approval, :lapsed_member)
    answer = {}
    Delayed::Worker.delay_jobs = true
    assert_difference("DelayedJob.count", 2) do  # :send_recover_needs_approval_email_dj_without_delay, :asyn_solr_index_without_delay
      answer = member.recover(@tom_approval)
    end
    Delayed::Worker.delay_jobs = false
    Delayed::Job.all.each{ |x| x.invoke_job }
    member.reload
    assert answer[:code] == Settings.error_codes.success, answer[:message]
    assert_equal 'applied', member.status
    assert_equal 1, member.reactivation_times
  end

  test "Recovered member in applied status is rejected. Reactivation times should stay at 0." do
    @tom_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
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
    member = create_active_member(@wordpress_terms_of_membership, :provisional_member_with_cc, nil, { :club_cash_amount => 200 })
    member.set_as_canceled
    assert_equal 0, member.club_cash_amount, "The member is #{member.status} with #{member.club_cash_amount}"
  end

  test "Canceled member should have cancel date set " do
    member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc)
    cancel_date = member.cancel_date
    member.cancel! Time.zone.now, "Cancel from Unit Test"
    m = Member.find member.id
    assert_not_nil m.cancel_date 
    assert_nil cancel_date
    assert m.cancel_date > m.join_date
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
    m = Member.find member.id
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
    m = Member.find member.id
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
    Time.zone = "UTC"
    saved_member = create_active_member(@terms_of_membership_with_gateway)
    saved_member.member_since_date = "Wed, 02 May 2012 19:10:51 UTC 00:00"
    saved_member.current_membership.join_date = "Wed, 03 May 2012 13:10:51 UTC 00:00"
    saved_member.next_retry_bill_date = "Wed, 03 May 2012 00:10:51 UTC 00:00"
    Time.zone = "Eastern Time (US & Canada)"
    assert_equal I18n.l(Time.zone.at(saved_member.member_since_date.to_i)), "05/02/2012"
    assert_equal I18n.l(Time.zone.at(saved_member.next_retry_bill_date.to_i)), "05/02/2012"
    assert_equal I18n.l(Time.zone.at(saved_member.current_membership.join_date.to_i)), "05/03/2012"
    Time.zone = "Ekaterinburg"
    assert_equal I18n.l(Time.zone.at(saved_member.member_since_date.to_i)), "05/03/2012"
    assert_equal I18n.l(Time.zone.at(saved_member.next_retry_bill_date.to_i)), "05/03/2012"
    assert_equal I18n.l(Time.zone.at(saved_member.current_membership.join_date.to_i)), "05/03/2012"
  end

  test "Recycle credit card with billing success" do
    @club = @wordpress_terms_of_membership.club
    member = create_active_member(@wordpress_terms_of_membership, :provisional_member_with_cc)
    original_year = (Time.zone.now - 2.years).year
    member.credit_cards.each { |s| s.update_attribute :expire_year , original_year } # force to be expired!
    member.reload

    assert_difference('CreditCard.count', 0) do
      assert_difference('Operation.count', 4) do  # club cash, renewal, recycle, bill, set as active
        assert_difference('Transaction.count') do
          assert_equal member.recycled_times, 0
          answer = member.bill_membership
          member.reload
          assert_equal answer[:code], Settings.error_codes.success
          assert_equal original_year+3, Transaction.find(:all, :limit => 1, :order => 'created_at desc', :conditions => ['member_id = ?', member.id]).first.expire_year
          assert_equal member.recycled_times, 0
          assert_equal member.credit_cards.count, 1 # only one credit card
          assert_equal member.active_credit_card.expire_year, original_year+3 # expire_year should be +3 years. 
        end
      end
    end
  end

  test "Billing for renewal amount" do
    @club = @wordpress_terms_of_membership.club
    member = create_active_member(@wordpress_terms_of_membership, :provisional_member_with_cc)    
    installment_period = @wordpress_terms_of_membership.installment_period.days
    assert_difference('Operation.count', 3) do
      prev_bill_date = member.next_retry_bill_date
      answer = member.bill_membership
      member.reload
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      assert_equal member.recycled_times, 0, "recycled_times is #{member.recycled_times} should be 0"
      assert_equal I18n.l(member.bill_date, :format => :only_date), I18n.l(member.next_retry_bill_date, :format => :only_date), "bill_date is #{member.bill_date} should be #{member.next_retry_bill_date}"
      assert_equal I18n.l(member.next_retry_bill_date, :format => :only_date), I18n.l(prev_bill_date + installment_period, :format => :only_date), "next_retry_bill_date is #{member.next_retry_bill_date} should be #{(prev_bill_date + installment_period)}"
    end


    Timecop.freeze(Time.zone.now + installment_period) do
      prev_bill_date = member.next_retry_bill_date
      answer = member.bill_membership
      member.reload
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      assert_equal member.recycled_times, 0, "recycled_times is #{member.recycled_times} should be 0"
      assert_equal I18n.l(member.bill_date, :format => :only_date), I18n.l(member.next_retry_bill_date, :format => :only_date), "bill_date is #{member.bill_date} should be #{member.next_retry_bill_date}"
      assert_equal I18n.l(member.next_retry_bill_date, :format => :only_date), I18n.l((prev_bill_date + installment_period), :format => :only_date), "next_retry_bill_date is #{member.next_retry_bill_date} should be #{(prev_bill_date + 1.month)}"
    end
  end

  # Prevent club to be billed
  test "Member should not be billed if club's billing_enable is set as false" do
    @club = @terms_of_membership_with_gateway.club
    @club.update_attribute(:billing_enable, false)
    @member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc)

    @member.current_membership.update_attribute(:join_date, Time.zone.now-2.month)
    next_bill_date_before = @member.next_retry_bill_date
    bill_date_before = @member.bill_date

    Timecop.freeze( @member.next_retry_bill_date ) do
      assert_difference('Operation.count', 0) do
        assert_difference('Transaction.count', 0) do
          excecute_like_server(@club.time_zone){ TasksHelpers.bill_all_members_up_today }
        end
      end
      @member.reload
      assert_equal(next_bill_date_before,@member.next_retry_bill_date)
      assert_equal(bill_date_before,@member.bill_date)
    end
  end

  # # Prevent club to be billed
  test "Member should be billed if club's billing_enable is set as true" do
    @club = @wordpress_terms_of_membership.club
    @member = create_active_member(@wordpress_terms_of_membership, :provisional_member_with_cc)

    @member.current_membership.update_attribute(:join_date, Time.zone.now-2.month)
    next_bill_date_before = @member.next_retry_bill_date
    bill_date_before = @member.bill_date

    Timecop.freeze( @member.next_retry_bill_date ) do
      assert_difference('Operation.count', 3) do
        assert_difference('Transaction.count', 1) do
          excecute_like_server(@club.time_zone) do
            TasksHelpers.bill_all_members_up_today
          end
        end
      end

      @member.reload
      assert_not_equal(next_bill_date_before,@member.next_retry_bill_date)
      assert_not_equal(bill_date_before,@member.bill_date)
    end
  end

  test "Change member from Lapsed status to active status" do
    @club = @terms_of_membership_with_gateway.club
    Time.zone = @club.time_zone
    @saved_member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc)
    @saved_member.set_as_canceled
    
    @saved_member.recover(@terms_of_membership_with_gateway)

    next_bill_date = @saved_member.bill_date + @terms_of_membership_with_gateway.installment_period.days

    Timecop.freeze( @saved_member.next_retry_bill_date ) do
      excecute_like_server(@club.time_zone) do
        TasksHelpers.bill_all_members_up_today
      end
      @saved_member.reload

      assert_equal(@saved_member.current_membership.status, "active")
      assert_equal(I18n.l(@saved_member.next_retry_bill_date, :format => :only_date), I18n.l(next_bill_date, :format => :only_date))
    end
  end

  test "Add club cash - more than maximum value on a member related to drupal" do
    agent = FactoryGirl.create(:confirmed_admin_agent)
    club = FactoryGirl.create(:club_with_api)
    member = FactoryGirl.create(:member_with_api, :club_id => @club.id)

    answer = member.add_club_cash(agent, 12385243.2)
  end

  test "save the sale should update membership" do
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @saved_member = create_active_member(@terms_of_membership, :provisional_member_with_cc)

    old_membership_id = @saved_member.current_membership_id
    @saved_member.save_the_sale @terms_of_membership2.id
    @saved_member.reload
      
    assert_equal @saved_member.current_membership.status, @saved_member.status
    assert_equal @saved_member.current_membership.cancel_date, nil
    assert_equal @saved_member.current_membership.parent_membership_id, old_membership_id
  end

  test "save the sale should not update membership if it failed" do
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @saved_member = create_active_member(@terms_of_membership, :provisional_member_with_cc)
    answer = {:code => 500, message => "Error on sts"}
    Member.any_instance.stubs(:enroll).returns(answer)

    @saved_member.save_the_sale @terms_of_membership2.id
    @saved_member.reload
      
    assert_equal @saved_member.current_membership.status, @saved_member.status
    assert_equal @saved_member.current_membership.cancel_date, nil
  end

  test "Downgrade member should fill parent_membership_id" do
    terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    terms_of_membership_with_gateway_to_downgrade = FactoryGirl.create(:terms_of_membership_for_downgrade, :club_id => @club.id)
    terms_of_membership.update_attributes(:if_cannot_bill => "downgrade_tom", :downgrade_tom_id => terms_of_membership_with_gateway_to_downgrade.id)
    saved_member = create_active_member(terms_of_membership, :provisional_member_with_cc)
    old_membership_id = saved_member.current_membership_id
    saved_member.downgrade_member
    saved_member.reload
      
    assert_equal saved_member.current_membership.parent_membership_id, old_membership_id
  end

  test "Upgrade member should fill parent_membership_id" do
    terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    terms_of_membership2 = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    terms_of_membership.upgrade_tom_id = terms_of_membership2.id
    terms_of_membership.upgrade_tom_period = 0
    terms_of_membership.save(validate: false)
    saved_member = create_active_member(terms_of_membership, :provisional_member_with_cc)
    old_membership_id = saved_member.current_membership_id
    Timecop.travel(saved_member.next_retry_bill_date) do
      saved_member.bill_membership
    end
    assert_equal saved_member.current_membership.parent_membership_id, old_membership_id
  end

  test "manual payment member should be canceled when its billing date is overdue" do
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @saved_member = create_active_member(@terms_of_membership, :provisional_member_with_cc)
    @saved_member.manual_payment =true
    @saved_member.bill_date = Time.zone.now-1.day
    @saved_member.save
    assert_difference("Operation.count",3) do
      excecute_like_server(@club.time_zone) do
        TasksHelpers.cancel_all_member_up_today
      end
    end
    @saved_member.reload
    assert_equal @saved_member.status, "lapsed"
    assert_nil @saved_member.next_retry_bill_date
    assert @saved_member.cancel_date.utc > @saved_member.join_date.utc, "#{@saved_member.cancel_date.utc} Not > #{@saved_member.join_date.utc}"
    assert Operation.find_by_operation_type(Settings.operation_types.bill_overdue_cancel)
  end 

  test "Member email validation" do
    member = create_active_member(@terms_of_membership_with_gateway, :provisional_member)
    300.times do
      member.update_attribute :email, Faker::Internet.email
      assert member.valid?, "Member with email #{member.email} is not valid."
    end
    ['name@do--main.com', 'name@do-ma-in.com.ar', 'name2@do.ma-in.com', 'name3@d.com'].each do |valid_email|
      member.update_attribute :email, valid_email
      assert member.valid?, "Member with email #{member.email} is not valid"
    end
    ['name@do--main..com', 'name@-do-ma-in.com.ar', '', nil, 'name@domain@domain.com', '..'].each do |wrong_email|
      member.update_attribute :email, wrong_email
      assert !member.valid?, "Member with email #{member.email} is valid when it should not be."
    end   
  end

  # ##################################################
  # # => PREBILL
  # ##################################################

  test "Send Prebill email (7 days before NBD)" do
    member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc)    

    excecute_like_server(@club.time_zone) do 
      Timecop.travel(member.next_retry_bill_date-7.days) do
        assert_difference("Operation.count") do
         assert_difference("Communication.count") do
            TasksHelpers.send_prebill
          end
        end
      end
    end 
    member.reload
    assert_equal member.communications.last.template_name, "Test prebill"
  end

  test "Do not Send Prebill email (7 days before NBD) when member's installment_amount is 0" do
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :installment_amount => 0)
    member = create_active_member(@terms_of_membership, :provisional_member_with_cc)
    
    excecute_like_server(@club.time_zone) do 
      Timecop.travel(member.next_retry_bill_date-7.days) do
        assert_difference("Operation.count",0) do
          assert_difference("Communication.count",0) do
            TasksHelpers.send_prebill
          end
        end
      end
    end
  end

  test "Do not Send Prebill email (7 days before NBD) when member's recycled_times is not 0" do
    member = create_active_member(@terms_of_membership_with_gateway, :provisional_member_with_cc)    
    member.update_attribute :recycled_times, 1
    
    excecute_like_server(@club.time_zone) do 
      Timecop.travel(member.next_retry_bill_date-7.days) do
        assert_difference("Operation.count",0) do
          assert_difference("Communication.count",0) do
            TasksHelpers.send_prebill
          end
        end
      end
    end
  end
end
