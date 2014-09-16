# encoding: utf-8
require 'test_helper'

class UserTest < ActiveSupport::TestCase

  setup do
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @partner = @club.partner
    Time.zone = @club.time_zone

    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @wordpress_terms_of_membership = FactoryGirl.create :wordpress_terms_of_membership_with_gateway, :club_id => @club.id
    @sd_strategy = FactoryGirl.create(:soft_decline_strategy)
  end

  test "Should create an user" do
    user = FactoryGirl.build(:user)
    assert !user.save, user.errors.inspect
    user.club = @terms_of_membership_with_gateway.club
    Delayed::Worker.delay_jobs = true
    assert_difference('Delayed::Job.count', 3, 'should create job for #desnormalize_preferences and mkt tool sync') do
      assert user.save, "user cant be save #{user.errors.inspect}"
    end
    Delayed::Worker.delay_jobs = false
  end

  test "Should not create an user without first name" do
    user = FactoryGirl.build(:user, :first_name => nil)
    assert !user.save
  end

  test "Should not create an user without last name" do
    user = FactoryGirl.build(:user, :last_name => nil)
    assert !user.save
  end

  test "Should create an user without gender" do
    user = FactoryGirl.build(:user, :gender => nil)
    assert !user.save
  end

  test "Should create an user without type_of_phone_number" do
    user = FactoryGirl.build(:user, :type_of_phone_number => nil)
    assert !user.save
  end

  test "User should not be billed if it is not active or provisional" do
    user = create_active_user(@terms_of_membership_with_gateway, :lapsed_user)
    answer = user.bill_membership
    assert !(answer[:code] == Settings.error_codes.success), answer[:message]
  end

  test "User should not be billed if no credit card is on file." do
    user = create_active_user(@terms_of_membership_with_gateway, :provisional_user)
    answer = user.bill_membership
    assert (answer[:code] != Settings.error_codes.success), answer[:message]
  end

  test "Insfufficient funds hard decline" do
    active_user = create_active_user(@terms_of_membership_with_gateway)
    answer = active_user.bill_membership
    assert (answer[:code] == Settings.error_codes.success), answer[:message]
  end

  test "Monthly user should be billed if it is active or provisional" do
    assert_difference('Operation.count', 3) do
      user = create_active_user(@wordpress_terms_of_membership, :provisional_user_with_cc)
      prev_bill_date = user.next_retry_bill_date
      answer = user.bill_membership
      user.reload
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      assert_equal user.recycled_times, 0, "recycled_times is #{user.recycled_times} should be 0"
      assert_equal user.bill_date, user.next_retry_bill_date, "bill_date is #{user.bill_date} should be #{user.next_retry_bill_date}"
      assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l((prev_bill_date + user.terms_of_membership.installment_period.days), :format => :only_date), "next_retry_bill_date is #{user.next_retry_bill_date} should be #{(prev_bill_date + 1.month)}"
    end
  end

  test "Should not save with an invalid email" do
    user = FactoryGirl.build(:user, :email => 'testing.com.ar')
    user.valid?
    assert_not_nil user.errors, user.errors.full_messages.inspect
  end

  test "Should not be two users with the same email within the same club" do
    user = FactoryGirl.build(:user)
    user.club =  @terms_of_membership_with_gateway.club
    user.save
    user_two = FactoryGirl.build(:user)
    user_two.club =  @terms_of_membership_with_gateway.club
    user_two.email = user.email
    user_two.valid?
    assert_not_nil user_two, user_two.errors.full_messages.inspect
  end

  test "Should let save two users with the same email in differents clubs" do
    @second_club = FactoryGirl.create(:simple_club_with_gateway)

    user = FactoryGirl.build(:user, email: 'testing@xagax.com', club: @terms_of_membership_with_gateway.club)
    user.club_id = 1
    user.save
    user_two = FactoryGirl.build(:user, email: 'testing@xagax.com', club: @second_club)
    assert user_two.save, "user cant be save #{user_two.errors.inspect}"
  end

  test "active user cant be recovered" do
    user = create_active_user(@terms_of_membership_with_gateway)
    tom_dup = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    
    answer = user.recover(tom_dup)
    assert answer[:code] == Settings.error_codes.user_already_active, answer[:message]
  end

  test "Lapsed user with reactivation_times = 5 cant be recovered" do
    user = create_active_user(@terms_of_membership_with_gateway)
    user.set_as_canceled!
    user.update_attribute( :reactivation_times, 5 )
    tom_dup = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)

    answer = user.recover(tom_dup)
    assert answer[:code] == Settings.error_codes.cant_recover_user, answer[:message]
  end

  test "Lapsed user can be recovered" do
    assert_difference('Fulfillment.count',Club::DEFAULT_PRODUCT.count) do
      user = create_active_user(@terms_of_membership_with_gateway, :lapsed_user)
      old_membership_id = user.current_membership_id 
      answer = user.recover(@terms_of_membership_with_gateway)
      assert answer[:code] == Settings.error_codes.success, answer[:message]
      assert_equal 'provisional', user.status, "Status was not updated."
      assert_equal 1, user.reactivation_times, "Reactivation_times was not updated."
      assert_equal user.current_membership.parent_membership_id, nil
    end
  end

  # When enrolling/recovering an user should send approval email as DJ
  test "Lapsed user can be recovered unless it needs approval" do
    @tom_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    user = create_active_user(@tom_approval, :lapsed_user)
    answer = {}
    Delayed::Worker.delay_jobs = true
    assert_difference("DelayedJob.count", 2) do  # :send_recover_needs_approval_email_dj_without_delay, :asyn_solr_index_without_delay
      answer = user.recover(@tom_approval)
    end
    Delayed::Worker.delay_jobs = false
    Delayed::Job.all.each{ |x| x.invoke_job }
    user.reload
    assert answer[:code] == Settings.error_codes.success, answer[:message]
    assert_equal 'applied', user.status
    assert_equal 1, user.reactivation_times
  end

  test "Recovered user in applied status is rejected. Reactivation times should stay at 0." do
    @tom_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    user = create_active_user(@tom_approval, :lapsed_user)
    answer = user.recover(@tom_approval)
    user.reload
    assert answer[:code] == Settings.error_codes.success, answer[:message]
    assert_equal 'applied', user.status
    assert_equal 1, user.reactivation_times
    user.set_as_canceled
    user.reload
    assert_equal 'lapsed', user.status
    assert_equal 0, user.reactivation_times
  end


  test "Should not let create an user with a wrong format zip" do
    ['12345-1234', '12345'].each {|zip| zip
      user = FactoryGirl.build(:user, zip: zip, club: @terms_of_membership_with_gateway.club)
      assert user.save, "User cant be save #{user.errors.inspect}"
    }    
    ['1234-1234', '12345-123', '1234'].each {|zip| zip
      user = FactoryGirl.build(:user, zip: zip, club: @terms_of_membership_with_gateway.club)
      assert !user.save, "User cant be save #{user.errors.inspect}"
    }        
  end

  #Check cancel email
  test "If user is rejected, when recovering it should increment reactivation_times" do
    user = create_active_user(@terms_of_membership_with_gateway, :applied_user)
    user.set_as_canceled!
    answer = user.recover(@terms_of_membership_with_gateway)
    user.reload
    assert answer[:code] == Settings.error_codes.success, answer[:message]
    assert_equal 'provisional', user.status
    assert_equal 1, user.reactivation_times
  end

  test "Should reset club_cash when user is canceled" do
    user = create_active_user(@wordpress_terms_of_membership, :provisional_user_with_cc, nil, { :club_cash_amount => 200 })
    user.set_as_canceled
    assert_equal 0, user.club_cash_amount, "The user is #{user.status} with #{user.club_cash_amount}"
  end

  test "Canceled user should have cancel date set " do
    user = create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc)
    cancel_date = user.cancel_date
    user.cancel! Time.zone.now, "Cancel from Unit Test"
    m = User.find user.id
    assert_not_nil m.cancel_date 
    assert_nil cancel_date
    assert m.cancel_date > m.join_date
  end

  test "User should be saved with first_name and last_name with numbers or acents." do
    user = FactoryGirl.build(:user)
    assert !user.save, user.errors.inspect
    user.club =  @terms_of_membership_with_gateway.club
    user.first_name = 'Billy 3ro'
    user.last_name = 'Sáenz'
    assert user.save, "user cant be save #{user.errors.inspect}"
  end

  test "Should not deduct more club_cash than the user has" do
    user = create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc, nil, { :club_cash_amount => 200 })
    user.add_club_cash(-300)
    assert_equal 200, user.club_cash_amount, "The user is #{user.status} with $#{user.club_cash_amount}"
  end

  test "if active user is blacklisted, should have cancel date set " do
    user = create_active_user(@terms_of_membership_with_gateway)
    cancel_date = user.cancel_date
    # 2 operations : cancel and blacklist
    assert_difference('Operation.count', 4) do
      user.blacklist(nil, "Test")
    end
    m = User.find user.id
    assert_not_nil m.cancel_date 
    assert_nil cancel_date
    assert_equal m.blacklisted, true
  end

  test "if lapsed user is blacklisted, it should not be canceled again" do
    user = create_active_user(@terms_of_membership_with_gateway, :lapsed_user, nil, { reactivation_times: 5 })
    cancel_date = user.cancel_date
    assert_difference('Operation.count', 1) do
      user.blacklist(nil, "Test")
    end
    m = User.find user.id
    assert_not_nil m.cancel_date 
    assert_equal m.cancel_date.to_date, cancel_date.to_date
    assert_equal m.blacklisted, true
  end

  test "If user's email contains '@noemail.com' it should not send emails." do
    user = create_active_user(@terms_of_membership_with_gateway, :lapsed_user, nil, { email: "testing@noemail.com" })
    assert_difference('Operation.count', 1) do
      Communication.deliver!(:active, user)
    end
    assert_equal user.operations.last.description, "The email contains '@noemail.com' which is an empty email. The email won't be sent."
  end

  test "show dates according to club timezones" do
    Time.zone = "UTC"
    saved_user = create_active_user(@terms_of_membership_with_gateway)
    saved_user.member_since_date = "Wed, 02 May 2012 19:10:51 UTC 00:00"
    saved_user.current_membership.join_date = "Wed, 03 May 2012 13:10:51 UTC 00:00"
    saved_user.next_retry_bill_date = "Wed, 03 May 2012 00:10:51 UTC 00:00"
    Time.zone = "Eastern Time (US & Canada)"
    assert_equal I18n.l(Time.zone.at(saved_user.member_since_date.to_i)), "05/02/2012"
    assert_equal I18n.l(Time.zone.at(saved_user.next_retry_bill_date.to_i)), "05/02/2012"
    assert_equal I18n.l(Time.zone.at(saved_user.current_membership.join_date.to_i)), "05/03/2012"
    Time.zone = "Ekaterinburg"
    assert_equal I18n.l(Time.zone.at(saved_user.member_since_date.to_i)), "05/03/2012"
    assert_equal I18n.l(Time.zone.at(saved_user.next_retry_bill_date.to_i)), "05/03/2012"
    assert_equal I18n.l(Time.zone.at(saved_user.current_membership.join_date.to_i)), "05/03/2012"
  end

  test "Recycle credit card with billing success" do
    @club = @wordpress_terms_of_membership.club
    user = create_active_user(@wordpress_terms_of_membership, :provisional_user_with_cc)
    original_year = (Time.zone.now - 2.years).year
    user.credit_cards.each { |s| s.update_attribute :expire_year , original_year } # force to be expired!
    user.reload

    assert_difference('CreditCard.count', 0) do
      assert_difference('Operation.count', 4) do  # club cash, renewal, recycle, bill, set as active
        assert_difference('Transaction.count') do
          assert_equal user.recycled_times, 0
          answer = user.bill_membership
          user.reload
          assert_equal answer[:code], Settings.error_codes.success
          assert_equal original_year+3, Transaction.find(:all, :limit => 1, :order => 'created_at desc', :conditions => ['user_id = ?', user.id]).first.expire_year
          assert_equal user.recycled_times, 0
          assert_equal user.credit_cards.count, 1 # only one credit card
          assert_equal user.active_credit_card.expire_year, original_year+3 # expire_year should be +3 years. 
        end
      end
    end
  end

  test "Billing for renewal amount" do
    @club = @wordpress_terms_of_membership.club
    user = create_active_user(@wordpress_terms_of_membership, :provisional_user_with_cc)    
    installment_period = @wordpress_terms_of_membership.installment_period.days
    assert_difference('Operation.count', 3) do
      prev_bill_date = user.next_retry_bill_date
      answer = user.bill_membership
      user.reload
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      assert_equal user.recycled_times, 0, "recycled_times is #{user.recycled_times} should be 0"
      assert_equal I18n.l(user.bill_date, :format => :only_date), I18n.l(user.next_retry_bill_date, :format => :only_date), "bill_date is #{user.bill_date} should be #{user.next_retry_bill_date}"
      assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l(prev_bill_date + installment_period, :format => :only_date), "next_retry_bill_date is #{user.next_retry_bill_date} should be #{(prev_bill_date + installment_period)}"
    end


    Timecop.freeze(Time.zone.now + installment_period) do
      prev_bill_date = user.next_retry_bill_date
      answer = user.bill_membership
      user.reload
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      assert_equal user.recycled_times, 0, "recycled_times is #{user.recycled_times} should be 0"
      assert_equal I18n.l(user.bill_date, :format => :only_date), I18n.l(user.next_retry_bill_date, :format => :only_date), "bill_date is #{user.bill_date} should be #{user.next_retry_bill_date}"
      assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l((prev_bill_date + installment_period), :format => :only_date), "next_retry_bill_date is #{user.next_retry_bill_date} should be #{(prev_bill_date + 1.month)}"
    end
  end

  # Prevent club to be billed
  test "User should not be billed if club's billing_enable is set as false" do
    @club = @terms_of_membership_with_gateway.club
    @club.update_attribute(:billing_enable, false)
    @user = create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc)

    @user.current_membership.update_attribute(:join_date, Time.zone.now-2.month)
    next_bill_date_before = @user.next_retry_bill_date
    bill_date_before = @user.bill_date

    Timecop.freeze( @user.next_retry_bill_date ) do
      assert_difference('Operation.count', 0) do
        assert_difference('Transaction.count', 0) do
          excecute_like_server(@club.time_zone){ TasksHelpers.bill_all_members_up_today }
        end
      end
      @user.reload
      assert_equal(next_bill_date_before,@user.next_retry_bill_date)
      assert_equal(bill_date_before,@user.bill_date)
    end
  end

  # # Prevent club to be billed
  test "User should be billed if club's billing_enable is set as true" do
    @club = @wordpress_terms_of_membership.club
    @user = create_active_user(@wordpress_terms_of_membership, :provisional_user_with_cc)

    @user.current_membership.update_attribute(:join_date, Time.zone.now-2.month)
    next_bill_date_before = @user.next_retry_bill_date
    bill_date_before = @user.bill_date

    Timecop.freeze( @user.next_retry_bill_date ) do
      assert_difference('Operation.count', 3) do
        assert_difference('Transaction.count', 1) do
          excecute_like_server(@club.time_zone) do
            TasksHelpers.bill_all_members_up_today
          end
        end
      end

      @user.reload
      assert_not_equal(next_bill_date_before,@user.next_retry_bill_date)
      assert_not_equal(bill_date_before,@user.bill_date)
    end
  end

  test "Change user from Lapsed status to active status" do
    @club = @terms_of_membership_with_gateway.club
    Time.zone = @club.time_zone
    @saved_user = create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc)
    @saved_user.set_as_canceled
    
    @saved_user.recover(@terms_of_membership_with_gateway)

    next_bill_date = @saved_user.bill_date + @terms_of_membership_with_gateway.installment_period.days

    Timecop.freeze( @saved_user.next_retry_bill_date ) do
      excecute_like_server(@club.time_zone) do
        TasksHelpers.bill_all_members_up_today
      end
      @saved_user.reload

      assert_equal(@saved_user.current_membership.status, "active")
      assert_equal(I18n.l(@saved_user.next_retry_bill_date, :format => :only_date), I18n.l(next_bill_date, :format => :only_date))
    end
  end

  test "Add club cash - more than maximum value on an user related to drupal" do
    agent = FactoryGirl.create(:confirmed_admin_agent)
    club = FactoryGirl.create(:club_with_api)
    user = FactoryGirl.create(:user_with_api, :club_id => @club.id)

    answer = user.add_club_cash(agent, 12385243.2)
  end

  test "save the sale should update membership" do
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @saved_user = create_active_user(@terms_of_membership, :provisional_user_with_cc)

    old_membership_id = @saved_user.current_membership_id
    @saved_user.save_the_sale @terms_of_membership2.id
    @saved_user.reload
      
    assert_equal @saved_user.current_membership.status, @saved_user.status
    assert_equal @saved_user.current_membership.cancel_date, nil
    assert_equal @saved_user.current_membership.parent_membership_id, old_membership_id
  end

  test "save the sale should not update membership if it failed" do
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @saved_user = create_active_user(@terms_of_membership, :provisional_user_with_cc)
    answer = {:code => 500, message => "Error on sts"}
    User.any_instance.stubs(:enroll).returns(answer)

    @saved_user.save_the_sale @terms_of_membership2.id
    @saved_user.reload
      
    assert_equal @saved_user.current_membership.status, @saved_user.status
    assert_equal @saved_user.current_membership.cancel_date, nil
  end

  test "Downgrade user should fill parent_membership_id" do
    terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    terms_of_membership_with_gateway_to_downgrade = FactoryGirl.create(:terms_of_membership_for_downgrade, :club_id => @club.id)
    terms_of_membership.update_attributes(:if_cannot_bill => "downgrade_tom", :downgrade_tom_id => terms_of_membership_with_gateway_to_downgrade.id)
    saved_user = create_active_user(terms_of_membership, :provisional_user_with_cc)
    old_membership_id = saved_user.current_membership_id
    saved_user.downgrade_user
    saved_user.reload
      
    assert_equal saved_user.current_membership.parent_membership_id, old_membership_id
  end

  test "Upgrade user should fill parent_membership_id" do
    terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    terms_of_membership2 = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    terms_of_membership.upgrade_tom_id = terms_of_membership2.id
    terms_of_membership.upgrade_tom_period = 0
    terms_of_membership.save(validate: false)
    saved_user = create_active_user(terms_of_membership, :provisional_user_with_cc)
    old_membership_id = saved_user.current_membership_id
    Timecop.travel(saved_user.next_retry_bill_date) do
      saved_user.bill_membership
    end
    assert_equal saved_user.current_membership.parent_membership_id, old_membership_id
  end

  test "manual payment user should be canceled when its billing date is overdue" do
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @saved_user = create_active_user(@terms_of_membership, :provisional_user_with_cc)
    @saved_user.manual_payment =true
    @saved_user.bill_date = Time.zone.now-1.day
    @saved_user.save
    assert_difference("Operation.count",3) do
      excecute_like_server(@club.time_zone) do
        TasksHelpers.cancel_all_member_up_today
      end
    end
    @saved_user.reload
    assert_equal @saved_user.status, "lapsed"
    assert_nil @saved_user.next_retry_bill_date
    assert @saved_user.cancel_date.utc > @saved_user.join_date.utc, "#{@saved_user.cancel_date.utc} Not > #{@saved_user.join_date.utc}"
    assert Operation.find_by_operation_type(Settings.operation_types.bill_overdue_cancel)
  end 

  test "User email validation" do
    user = create_active_user(@terms_of_membership_with_gateway, :provisional_user)
    300.times do
      user.email = Faker::Internet.email
      user.save
      assert user.valid?, "User with email #{user.email} is not valid."
    end
    ['name@do--main.com', 'name@do-ma-in.com.ar', 'name2@do.ma-in.com', 'name3@d.com'].each do |valid_email|
      user.email = valid_email
      user.save
      assert user.valid?, "User with email #{user.email} is not valid"
    end
    ['name@do--main..com', 'name@-do-ma-in.com.ar', '', nil, 'name@domain@domain.com', '..'].each do |wrong_email|
      user.email = wrong_email
      user.save
      assert !user.valid?, "User with email #{user.email} is valid when it should not be."
    end   
  end

  test "If member's club does not have billing enable we should not send any communication." do
    saved_member = create_active_member(@terms_of_membership_with_gateway)
    saved_member.club.update_attribute :billing_enable, false
    saved_member.reload
    EmailTemplate::TEMPLATE_TYPES.each do |type|
      assert_difference('Operation.count', 0) do
        assert_difference('Communication.count', 0) do
          Communication.deliver!(type, saved_member)
        end
      end
    end
  end

  # ##################################################
  # # => PREBILL
  # ##################################################

  test "Send Prebill email (7 days before NBD)" do
    user = create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc)    

    excecute_like_server(@club.time_zone) do 
      Timecop.travel(user.next_retry_bill_date-7.days) do
        assert_difference("Operation.count") do
         assert_difference("Communication.count") do
            TasksHelpers.send_prebill
          end
        end
      end
    end 
    user.reload
    assert_equal user.communications.last.template_name, "Test prebill"
  end

  test "Do not Send Prebill email (7 days before NBD) when user's installment_amount is 0" do
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :installment_amount => 0)
    user = create_active_user(@terms_of_membership, :provisional_user_with_cc)
    
    excecute_like_server(@club.time_zone) do 
      Timecop.travel(user.next_retry_bill_date-7.days) do
        assert_difference("Operation.count",0) do
          assert_difference("Communication.count",0) do
            TasksHelpers.send_prebill
          end
        end
      end
    end
  end

  test "Do not Send Prebill email (7 days before NBD) when user's recycled_times is not 0" do
    user = create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc)    
    user.update_attribute :recycled_times, 1
    
    excecute_like_server(@club.time_zone) do 
      Timecop.travel(user.next_retry_bill_date-7.days) do
        assert_difference("Operation.count",0) do
          assert_difference("Communication.count",0) do
            TasksHelpers.send_prebill
          end
        end
      end
    end
  end

  test "Send communication with marketing client selected" do
    user = create_active_user(@terms_of_membership_with_gateway, :provisional_user_with_cc)    
    email_template_for_exact_target = FactoryGirl.create(:email_template_for_exact_target , :terms_of_membership_id => @terms_of_membership_with_gateway.id)
    email_template_for_mailchimp_mandrill = FactoryGirl.create(:email_template_for_mailchimp_mandrill, :terms_of_membership_id => @terms_of_membership_with_gateway.id)
    #configure exact target
    user.club.update_attributes :marketing_tool_client => "exact_target", :marketing_tool_attributes => { "et_business_unit" => "12345", "et_prospect_list" => "1235", "et_members_list" => "12345", "et_username" => "12345", "et_password" => "12345" }
    excecute_like_server(@club.time_zone) do 
      Timecop.travel(user.join_date + email_template_for_exact_target.days_after_join_date.days) do
        assert_difference("Communication.count",1) do
          TasksHelpers.send_pillar_emails 
        end
      end
    end
    user.reload
    communication = user.communications.where("client = 'exact_target'").first
    assert_equal "exact_target", communication.client
    assert_equal "pillar", communication.template_type

    #configure mandrill
    user.club.update_attributes :marketing_tool_client => "mailchimp_mandrill", :marketing_tool_attributes => { "mailchimp_api_key" => "12345", "mailchimp_list_id" => "1235", "mandrill_api_key" => "12345" }
    excecute_like_server(@club.time_zone) do 
      Timecop.travel(user.join_date + email_template_for_mailchimp_mandrill.days_after_join_date.days) do
        assert_difference("Communication.count",1) do
          TasksHelpers.send_pillar_emails
        end
      end
    end
    user.reload
    communication = user.communications.where("client = 'mailchimp_mandrill'").first
    assert_equal "mailchimp_mandrill", communication.client
    assert_equal "pillar", communication.template_type
  end
end
