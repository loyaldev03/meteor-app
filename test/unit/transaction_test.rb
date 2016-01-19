  require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    @current_agent = FactoryGirl.create(:agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_gateway_yearly = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    @user = FactoryGirl.build(:user)
    @credit_card = FactoryGirl.build(:credit_card)
    @sd_strategy = FactoryGirl.create(:soft_decline_strategy)
    @sd_mes_expired_strategy = FactoryGirl.create(:soft_decline_strategy, :response_code => "054")
    @sd_litle_expired_strategy = FactoryGirl.create(:soft_decline_strategy, :response_code => "305", :gateway => "litle")
    @sd_auth_net_expired_strategy = FactoryGirl.create(:soft_decline_strategy, :response_code => "316", :gateway => "authorize_net")
    @sd_first_data_expired_strategy = FactoryGirl.create(:soft_decline_strategy, :response_code => "605", :gateway => "first_data")
    @sd_stripe_expired_strategy = FactoryGirl.create(:soft_decline_strategy, :response_code => "card_declined", :gateway => "stripe")
    @hd_strategy = FactoryGirl.create(:hard_decline_strategy)
    FactoryGirl.create(:without_grace_period_decline_strategy_monthly)
    FactoryGirl.create(:without_grace_period_decline_strategy_yearly)
  end

  def enroll_user(tom, amount=23, cc_blank=false, cc_card = nil)
    credit_card = cc_card.nil? ? @credit_card : cc_card
    answer = User.enroll(tom, @current_agent, amount, 
      { first_name: @user.first_name,
        last_name: @user.last_name, address: @user.address, city: @user.city, gender: 'M',
        zip: @user.zip, state: @user.state, email: @user.email, type_of_phone_number: @user.type_of_phone_number,
        phone_country_code: @user.phone_country_code, phone_area_code: @user.phone_area_code, 
        phone_local_number: @user.phone_local_number, country: 'US', 
        product_sku: Settings.kit_card_product }, 
      { number: credit_card.number, 
        expire_year: credit_card.expire_year, expire_month: credit_card.expire_month },
      cc_blank)

    assert (answer[:code] == Settings.error_codes.success), answer[:message]+answer.inspect

    user = User.find(answer[:member_id])
    assert_not_nil user
    assert_equal user.status, 'provisional'
    user
  end

  test "save operation" do
    user = enroll_user(@terms_of_membership)
    assert_difference('Operation.count') do
      Auditory.audit(@current_agent, nil, "test", user)
    end
  end

  test "Enrollment with approval" do
    @tom_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    active_merchant_stubs
    assert_difference('Operation.count',2) do
      assert_no_difference('Fulfillment.count') do
        answer = User.enroll(@tom_approval, @current_agent, 23, 
          { first_name: @user.first_name,
            last_name: @user.last_name, address: @user.address, city: @user.city, gender: 'M',
            zip: @user.zip, state: @user.state, email: @user.email, type_of_phone_number: @user.type_of_phone_number,
            phone_country_code: @user.phone_country_code, phone_area_code: @user.phone_area_code,
            phone_local_number: @user.phone_local_number, country: 'US', :product_sku => Settings.kit_card_product }, 
          { number: @credit_card.number, 
            expire_year: @credit_card.expire_year, expire_month: @credit_card.expire_month })
        assert (answer[:code] == Settings.error_codes.success), answer[:message]
        user = User.find(answer[:member_id])
        assert_not_nil user
        assert_not_nil user.join_date, "join date should not be nil"
        assert_nil user.bill_date, "bill date should be nil"
        assert_equal 'applied', user.status
      end
    end
  end

  test "Enrollment without approval" do
    active_merchant_stubs
    assert_difference('Operation.count',3) do   #EnrollBilling, club cash and EnrollmentInfo operations.
      assert_difference('Fulfillment.count') do
        user = enroll_user(@terms_of_membership)
        assert_not_nil user.next_retry_bill_date, "NBD should not be nil"
        assert_not_nil user.join_date, "join date should not be nil"
        assert_not_nil user.bill_date, "bill date should not be nil"
        assert_equal user.recycled_times, 0, "recycled_times should be 0"
        assert_not_nil user.transactions.find_by(operation_type: Settings.operation_types.enrollment_billing, transaction_type: 'sale')
      end
    end
  end

  test "controlled refund (refund completely a transaction)" do
    active_merchant_stubs_store
    active_merchant_stubs_purchase
    active_user = create_active_user(@terms_of_membership)
    amount = @terms_of_membership.installment_amount
    active_user.update_attribute :next_retry_bill_date, Time.zone.now
    answer = active_user.bill_membership
    active_user.reload
    assert_equal active_user.status, 'active'
    assert_difference('Operation.count', 2) do
      assert_difference('Transaction.count') do
        assert_difference('Communication.count') do
          trans = active_user.transactions.find_by(operation_type: Settings.operation_types.membership_billing)
          answer = Transaction.refund(amount, trans.id)
          assert_equal answer[:code], Settings.error_codes.success, answer[:message]
          trans.reload
          active_user.reload
          assert_equal trans.refunded_amount, amount
          assert_equal trans.amount_available_to_refund, 0.0
          assert_not_nil active_user.transactions.find_by(operation_type: Settings.operation_types.credit)
        end 
      end
    end
  end

  test "Monthly user billed 24 months" do 
    active_merchant_stubs

    user = enroll_user(@terms_of_membership)
    nbd = user.next_retry_bill_date
    next_month = Time.zone.now.to_date + user.terms_of_membership.installment_period.days

    # bill users the day before trial days expires. User should not be billed
    Timecop.travel(Time.zone.now + user.terms_of_membership.provisional_days.days - 2.days) do
      TasksHelpers.bill_all_members_up_today
      user.reload
      assert_equal I18n.l(nbd, :format => :only_date), I18n.l(user.bill_date, :format => :only_date)
    end

    # bill users the day trial days expires. User should be billed
    Timecop.travel(Time.zone.now + user.terms_of_membership.provisional_days.days) do
      TasksHelpers.bill_all_members_up_today
      user.reload
      nbd = nbd + user.terms_of_membership.installment_period.days
      assert_equal I18n.l(nbd, :format => :only_date), I18n.l(user.next_retry_bill_date, :format => :only_date)
      assert_equal user.bill_date, user.next_retry_bill_date
    end

    club_cash = user.club_cash_amount

    actual_month = user.next_retry_bill_date
    1.upto(24) do |time|
      Timecop.travel(actual_month) do
        actual_month = user.next_retry_bill_date + user.terms_of_membership.installment_period.days
        TasksHelpers.bill_all_members_up_today
        user.reload
        nbd = nbd + user.terms_of_membership.installment_period.days
        assert_equal I18n.l(nbd, :format => :only_date), I18n.l(user.next_retry_bill_date, :format => :only_date) 
        assert_equal user.bill_date, user.next_retry_bill_date
        assert_equal user.recycled_times, 0
        assert_equal user.club_cash_amount, club_cash+@terms_of_membership.club_cash_installment_amount
        club_cash = user.club_cash_amount
      end
    end
  end

  test "Yearly user billed 4 years" do 
    active_merchant_stubs

    # if we use 5 years take care to have a credit card that does not get expired.
    @credit_card.expire_year = Time.zone.now.year + 7

    user = enroll_user(@terms_of_membership_with_gateway_yearly)
    nbd = user.bill_date

    # bill users the day before trial days expires. User should not be billed
    Timecop.travel(Time.zone.now + user.terms_of_membership.provisional_days.days - 2.days) do
      TasksHelpers.bill_all_members_up_today
      user.reload
      assert_equal nbd, user.bill_date
    end

    # bill users the day trial days expires. User should be billed
    Timecop.travel(Time.zone.now + user.terms_of_membership.provisional_days.days) do
      Delayed::Worker.delay_jobs = true
      assert_difference('DelayedJob.count',3)do  # asign_club_cash  membership_bill_communication  elasticsearch_sync
        TasksHelpers.bill_all_members_up_today
      end
      Delayed::Worker.delay_jobs = false  
      Delayed::Job.all.each{ |x| x.invoke_job }
      user.reload
      nbd = nbd + user.terms_of_membership.installment_period.days
      assert_equal I18n.l(nbd, :format => :only_date), I18n.l(user.next_retry_bill_date, :format => :only_date)
      assert_equal user.bill_date, user.next_retry_bill_date
    end

    next_year = user.next_retry_bill_date
    2.upto(5) do |time|
      Timecop.travel(next_year) do
        next_year = next_year + user.terms_of_membership.installment_period.days
        Delayed::Worker.delay_jobs = true
        assert_difference('DelayedJob.count',3) do  # asign_club_cash , renewal_membership_communication, membership_bill_communication
          TasksHelpers.bill_all_members_up_today
        end
        Delayed::Worker.delay_jobs = false
        Delayed::Job.all.each{ |x| x.invoke_job }
        user.reload
        nbd = nbd + user.terms_of_membership.installment_period.days
        assert_equal I18n.l(nbd, :format => :only_date), I18n.l(user.next_retry_bill_date, :format => :only_date)
        assert_equal user.bill_date, user.next_retry_bill_date
        assert_equal user.recycled_times, 0
      end
    end
  end

  ######################################
  ############ DECLINE ###################
  test "Monthly user SD until gets HD" do 
    active_merchant_stubs_store
    active_merchant_stubs
 
    user = enroll_user(@terms_of_membership)
    nbd = user.bill_date
    bill_date = user.bill_date
    
    active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false)

    # bill users the day trial days expires. User should be billed but SD'd
    Timecop.travel(Time.zone.now + user.terms_of_membership.provisional_days.days) do
      TasksHelpers.bill_all_members_up_today
      user.reload
      nbd = nbd + @sd_strategy.days.days
      assert_equal nbd.to_date, user.next_retry_bill_date.to_date
      assert_equal bill_date, user.bill_date
      assert_not_equal user.bill_date, user.next_retry_bill_date
      assert_equal 1, user.recycled_times
    end
    # SD retries
    user.reload
    nbd = user.next_retry_bill_date
    2.upto(15) do |time|
      Timecop.travel(nbd) do
        user.bill_membership
        user.reload
        if user.next_retry_bill_date.nil?
          cancel_date = user.cancel_date
          assert_equal cancel_date, user.cancel_date
          assert_nil user.next_retry_bill_date
          assert_nil user.bill_date
          assert_not_nil user.cancel_date
          assert_equal 0, user.recycled_times
          assert_equal 1, user.operations.where(operation_type: Settings.operation_types.membership_billing_hard_decline_by_max_retries).count
        else
          nbd = nbd + @sd_strategy.days.days
          assert_equal nbd.to_date, user.next_retry_bill_date.to_date
          assert_equal bill_date, user.bill_date
          assert_not_equal user.bill_date, user.next_retry_bill_date
          assert_equal time, user.recycled_times
          assert_equal time, user.operations.where(operation_type: Settings.operation_types.membership_billing_soft_decline).count
        end
      end
    end
  end

  test "Monthly user SD until gets HD will downgrade the user" do 
    active_merchant_stubs_store
    active_merchant_stubs
    @terms_of_membership_for_downgrade = FactoryGirl.create(:terms_of_membership_for_downgrade, :club_id => @club.id)
    @terms_of_membership.downgrade_tom_id = @terms_of_membership_for_downgrade.id
    @terms_of_membership.if_cannot_bill = "downgrade_tom"
    @terms_of_membership.save
    
    user = enroll_user(@terms_of_membership)
    nbd = user.bill_date
    bill_date = user.bill_date
    
    active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false)
    # bill users the day trial days expires. User should be billed but SD'd
    Timecop.travel(Time.zone.now + user.terms_of_membership.provisional_days.days) do
      user.bill_membership
      user.reload
      nbd = nbd + @sd_strategy.days.days
      assert_equal nbd.to_date, user.next_retry_bill_date.to_date
      assert_equal bill_date, user.bill_date
      assert_not_equal user.bill_date, user.next_retry_bill_date
      assert_equal 1, user.recycled_times
    end
    # SD retries
    user.reload
    nbd = user.next_retry_bill_date
    2.upto(15) do |time|
      Timecop.travel(nbd) do
        TasksHelpers.bill_all_members_up_today
        user.reload
        if @terms_of_membership_for_downgrade.id == user.terms_of_membership.id
          assert_nil user.cancel_date
          assert_not_nil user.bill_date          
          assert_not_nil user.next_retry_bill_date          
          assert_equal 1, user.operations.where(operation_type: Settings.operation_types.downgraded_because_of_hard_decline_by_max_retries).count
          assert_equal 0, user.recycled_times
        else
          nbd = nbd + @sd_strategy.days.days
          assert_equal nbd.to_date, user.next_retry_bill_date.to_date
          assert_equal bill_date, user.bill_date
          assert_not_equal user.bill_date, user.next_retry_bill_date
          assert_equal time, user.recycled_times
          assert_equal time, user.operations.where(operation_type: Settings.operation_types.membership_billing_soft_decline).count
        end
      end
    end
  end

  test "Downgrade due to soft decline should update NRBD and BD according to new Terms of membership provisional days." do 
    active_merchant_stubs_store
    active_merchant_stubs
    @terms_of_membership_for_downgrade = FactoryGirl.create(:terms_of_membership_for_downgrade, :club_id => @club.id, provisional_days: 30)
    @terms_of_membership.downgrade_tom_id = @terms_of_membership_for_downgrade.id
    @terms_of_membership.if_cannot_bill = "downgrade_tom"
    @terms_of_membership.save
    
    user = enroll_user(@terms_of_membership)
    
    Timecop.travel(user.next_retry_bill_date) do
      user.bill_membership
    end
    user.reload
    
    active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false)

    (@sd_strategy.max_retries + 1).times do |time| 
      Timecop.travel(user.next_retry_bill_date) do
        TasksHelpers.bill_all_members_up_today
        user.reload
      end
    end
    assert_equal user.bill_date.to_date, (user.current_membership.join_date + user.terms_of_membership.provisional_days.days).to_date
    assert_equal user.next_retry_bill_date.to_date, (user.current_membership.join_date + user.terms_of_membership.provisional_days.days).to_date
  end

  test "Billing with SD is re-scheduled" do 
    active_merchant_stubs_store
    assert_difference('Operation.count', 3) do
      assert_difference('Transaction.count') do
        active_user = create_active_user(@terms_of_membership)
        active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false)
        nbd = active_user.bill_date
        answer = active_user.bill_membership
        active_user.reload
        assert !active_user.lapsed?, "user cant be lapsed"
        assert_equal active_user.next_retry_bill_date.to_date, @sd_strategy.days.days.from_now.to_date, "next_retry_bill_date should #{@sd_strategy.days.days.from_now}"
        assert_equal active_user.bill_date, nbd, "bill_date should not be touched #{nbd}"
        assert_equal active_user.recycled_times, 1, "recycled_times should be 1"
        assert_not_nil active_user.transactions.find_by(operation_type: Settings.operation_types.membership_billing_soft_decline, transaction_type: 'sale')
      end
    end
  end

  test "Chargeback an user" do 
    active_merchant_stubs_store
    active_user = create_active_user(@terms_of_membership)
    nbd = active_user.bill_date
    answer = active_user.bill_membership
    active_user.reload
    assert !active_user.lapsed?, "user cant be lapsed"
    
    trans = Transaction.where("operation_type = 101").first
    active_user.chargeback!(trans,{:reason => "testing", :transaction_amount => trans.amount, :auth_code => trans.response_auth_code, adjudication_date: (Time.zone.now).to_s })
    chargeback_trans = Transaction.find_by_operation_type 110
    assert_equal chargeback_trans.amount, -trans.amount
  end

  test "Billing with grace period disable on tom and missing CC" do
    active_user = create_active_user( @terms_of_membership, :active_user_without_cc )
    blank_cc = FactoryGirl.create( :blank_credit_card, :user_id => active_user.id )

    nbd = active_user.bill_date
    assert_difference('Operation.count', 5) do
      assert_difference('Communication.count', 2) do
        assert_difference('Transaction.count', 1) do
          answer = active_user.bill_membership
          active_user.reload
          assert_equal active_user.status, "lapsed"
          assert (answer[:code] != Settings.error_codes.success), "#{answer[:code]} cant be 000 (success)"
        end
      end
    end
  end

  test "Should not bill user which is not being spected to be billed (is_payment_expected = false)" do
    @terms_of_membership_not_expected_to_be_billed = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :is_payment_expected => false)
    active_user = create_active_user( @terms_of_membership_not_expected_to_be_billed )
    blank_cc = FactoryGirl.create( :blank_credit_card, :user_id => active_user.id )

    Timecop.travel(active_user.next_retry_bill_date+1.day) do
      assert_difference('Operation.count', 0) do
        assert_difference('Communication.count', 0) do
          assert_difference('Transaction.count', 0) do
            TasksHelpers.bill_all_members_up_today
          end
        end
      end
    end
    Timecop.travel(active_user.next_retry_bill_date+10.day) do
      assert_difference('Operation.count', 0) do
        assert_difference('Communication.count', 0) do
          assert_difference('Transaction.count', 0) do
            answer = active_user.bill_membership
            assert_equal "User is not expected to get billed.", answer[:message]
            assert_equal Settings.error_codes.user_not_expecting_billing, answer[:code]
          end
        end
      end
    end
  end

  test "Billing with SD reaches the recycle limit, and HD cancels user." do 
    active_merchant_stubs_store
    assert_difference('Operation.count', 6) do
      assert_difference('Communication.count', 2) do
        active_user = create_active_user(@terms_of_membership)
        active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false) 
        amount = @terms_of_membership.installment_amount
        active_user.recycled_times = 4
        active_user.save
        answer = active_user.bill_membership
        active_user.reload
        assert (answer[:code] != Settings.error_codes.success), "#{answer[:code]} cant be 000 (success)"
        assert active_user.lapsed?, "user should be lapsed after recycle limit is reached"
        assert_nil active_user.next_retry_bill_date, "next_retry_bill_date should be nil"
        assert_nil active_user.bill_date, "bill_date should be nil"
        assert_equal active_user.recycled_times, 0, "recycled_times should be 0"
        assert_not_nil active_user.transactions.find_by(operation_type: Settings.operation_types.membership_billing_hard_decline_by_max_retries, transaction_type: 'sale')
      end
    end
  end

  test "Billing with HD cancels user" do 
    active_merchant_stubs_store
    active_user = create_active_user(@terms_of_membership)
    active_merchant_stubs(@hd_strategy.response_code, "decline stubbed", false)
    assert_difference('Operation.count', 5) do
      assert_difference('Communication.count', 2) do
        amount = @terms_of_membership.installment_amount
        answer = active_user.bill_membership
        active_user.reload
        assert active_user.lapsed?, "user should be lapsed after HD"
        assert_nil active_user.next_retry_bill_date, "next_retry_bill_date should be nil"
        assert_nil active_user.bill_date, "bill_date should be nil"
        assert_equal active_user.recycled_times, 0, "recycled_times should be 0"
        assert_not_nil active_user.transactions.find_by(operation_type: Settings.operation_types.membership_billing_hard_decline, transaction_type: 'sale')
      end
    end
  end

  test "Billing with SD reaches the recycle limit, and HD downgrade the user." do 
    @terms_of_membership_for_downgrade = FactoryGirl.create(:terms_of_membership_for_downgrade, :club_id => @club.id)
    @terms_of_membership.downgrade_tom_id = @terms_of_membership_for_downgrade.id
    @terms_of_membership.if_cannot_bill = "downgrade_tom"
    @terms_of_membership.save

    active_merchant_stubs_store
    assert_difference('Operation.count', 5) do
      active_user = create_active_user(@terms_of_membership)
      active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false) 
      amount = @terms_of_membership.installment_amount
      active_user.recycled_times = 4
      active_user.save
      answer = active_user.bill_membership
      active_user.reload
      assert (answer[:code] != Settings.error_codes.success), "#{answer[:code]} cant be 000 (success)"
      assert active_user.provisional?
      assert_equal active_user.recycled_times, 0
      assert_equal active_user.terms_of_membership.id, @terms_of_membership_for_downgrade.id
      assert_not_nil active_user.transactions.find_by(operation_type: Settings.operation_types.downgraded_because_of_hard_decline_by_max_retries, transaction_type: 'sale')
    end
  end

  test "Billing with HD downgrade the user when configured to do so" do 
    @terms_of_membership_for_downgrade = FactoryGirl.create(:terms_of_membership_for_downgrade, :club_id => @club.id)
    @terms_of_membership.downgrade_tom_id = @terms_of_membership_for_downgrade.id
    @terms_of_membership.if_cannot_bill = "downgrade_tom"
    @terms_of_membership.save

    active_merchant_stubs_store
    assert_difference('Operation.count', 5) do
      active_user = create_active_user(@terms_of_membership)
      active_merchant_stubs(@hd_strategy.response_code, "decline stubbed", false)
      amount = @terms_of_membership.installment_amount
      answer = active_user.bill_membership
      active_user.reload
      assert_equal active_user.recycled_times, 0, "recycled_times should be 0"
      assert_equal active_user.terms_of_membership.id, @terms_of_membership_for_downgrade.id
      assert_not_nil active_user.transactions.find_by(operation_type: Settings.operation_types.downgraded_because_of_hard_decline, transaction_type: "sale")
    end
  end

  test "Billing declined, but there is no decline rule. Send email" do 
    active_merchant_stubs_store
    active_user = create_active_user(@terms_of_membership)
    active_merchant_stubs("34234", "decline stubbed", false) 
    amount = @terms_of_membership.installment_amount
    answer = active_user.bill_membership
    active_user.reload
    assert_equal active_user.next_retry_bill_date.to_date, (Time.zone.now + eval(Settings.next_retry_on_missing_decline)).to_date, "Next retry bill date incorrect"
    trans = active_user.transactions.find_by(operation_type: Settings.operation_types.membership_billing_without_decline_strategy, transaction_type: "sale")
    assert_not_nil trans
    assert_equal Operation.find_by(user_id: active_user.id, operation_type: Settings.operation_types.membership_billing_without_decline_strategy).description, "Billing error. No decline rule configured: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
  end

  test "Billing declined, but there is no decline rule and limit is reached. Send email" do 
    active_merchant_stubs_store
    active_user = create_active_user(@terms_of_membership)
    active_user.update_attribute :recycled_times, 5
    active_merchant_stubs("34234", "decline stubbed", false) 
    amount = @terms_of_membership.installment_amount
    answer = active_user.bill_membership
    active_user.reload
    trans = active_user.transactions.find_by(operation_type: Settings.operation_types.membership_billing_without_decline_strategy_max_retries, transaction_type: "sale")
    assert_not_nil trans
    assert_equal Operation.find_by_user_id_and_operation_type(active_user.id, Settings.operation_types.membership_billing_without_decline_strategy_max_retries).description, "Billing error. No decline rule configured limit reached: #{trans.response_code} #{trans.gateway}: #{trans.response_result}"
  end

  # TODO: how do we stub faraday?
  test "Chargeback processing should create transaction, blacklist and cancel the user" do
    active_user = create_active_user(@terms_of_membership)
    transaction = FactoryGirl.create(:transaction, user: active_user, terms_of_membership: @terms_of_membership)
    answer = { :body => '"Merchant Id","DBA Name","Control Number","Incoming Date","Card Number","Reference Number",' + 
      '"Tran Date","Tran Amount","Trident Tran ID","Purchase ID","Client Ref Num","Auth Code","Adj Date",' +
      '"Adj Ref Num","Reason","First Time","Reason Code","CB Ref Num","Terminal ID"\n' +
      '"941000110030",""SAC*AO ADVENTURE CLUB"","2890810","07/26/2012","'+active_user.credit_cards.first.number.to_s+
      '","25247702125003734750438",'+
      '"05/03/2012","84.0","'+transaction.response_transaction_id+'","'+active_user.id.to_s+'",""'+
      active_user.id.to_s+'"","00465Z",""07/27/2012-""' +
      ',""00373475043"",""No Cardholder Authorization"","Y","4837","2206290194",""94100011003000000002""' }

    # assert_difference('Transaction', 1) do 
    #   PaymentGatewayConfiguration.process_mes_chargebacks('development')
    #   assert_equal active_user.blacklisted, true
    #   assert_equal active_user.status, "cancel"
    # end
  end

  test "enroll with monthly tom with no amount and cc blank" do
    @tom = FactoryGirl.create(:terms_of_membership_monthly_without_provisional_day_and_amount, :club_id => @club.id)
    @credit_card.number = "0000000000"
    active_merchant_stubs
    user = enroll_user(@tom, 0, true)

    assert_difference("Operation.count",4) do  # club cash | renewal schedule NBD | billing | memberhsip_bill_communication
      assert_difference("Transaction.count") do
        user.bill_membership
      end
    end
    assert_equal user.status, "active"
  end

  test "enroll with yearly tom with no amount and cc blank" do
    @tom = FactoryGirl.create(:terms_of_membership_yearly_without_provisional_day_and_amount, :club_id => @club.id)
    @credit_card.number = "0000000000"
    active_merchant_stubs
    user = enroll_user(@tom, 0, true)
    
    assert_difference("Operation.count",4) do  # club_cash | renewal schedule NBD | billing | membership_bill_communication
      assert_difference("Transaction.count") do
        user.bill_membership
      end
    end
    assert_equal user.status, "active"
  end

  # # Tets Litle transactions
  # def club_with_litle
  #   @litle_club = FactoryGirl.create(:simple_club_with_litle_gateway)
  #   @litle_terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @litle_club.id)
  #   @credit_card_litle = FactoryGirl.build(:credit_card_american_express_litle)
  #   active_merchant_stubs_litle
  # end

  # test "Bill membership with Litle" do
  #   club_with_litle
  #   @credit_card = @credit_card_litle # overwrite credit card
  #   active_user = enroll_user(@litle_terms_of_membership, 100, false, @credit_card_litle)
  #   amount = @litle_terms_of_membership.installment_amount
  #   Timecop.travel(active_user.next_retry_bill_date) do
  #     answer = active_user.bill_membership
  #     active_user.reload
  #     assert_equal active_user.status, 'active'
  #     assert_not_nil active_user.transactions.find_by(operation_type: Settings.operation_types.membership_billing, transaction_type: 'sale')
  #   end
  # end
  
  # test "Bill membership with wrong payment gateway cofiguration set" do
  #   user = enroll_user(@terms_of_membership)
  #   user.club.payment_gateway_configurations.first.update_attribute :gateway, "random_gateway"
  #   Timecop.travel(user.next_retry_bill_date) do
  #     answer = user.bill_membership
  #     assert answer[:message].include?("Error while processing this request. A ticket has been submitted to our IT crew, in order to fix this inconvenience")
  #   end
  # end 

  # test "Enroll with Litle" do
  #   club_with_litle
  #   enroll_user(@litle_terms_of_membership, 100, false, @credit_card_litle)
  # end

  # test "Full refund with Litle" do
  #   club_with_litle
  #   @credit_card = @credit_card_litle # overwrite credit card
  #   active_user = enroll_user(@litle_terms_of_membership, 100, false, @credit_card_litle)
  #   amount = @litle_terms_of_membership.installment_amount
  #   Timecop.travel(active_user.next_retry_bill_date) do
  #     answer = active_user.bill_membership
  #     active_user.reload
  #     assert_equal active_user.status, 'active'
  #     trans = Transaction.find(:all, :limit => 1, :order => 'created_at desc', :conditions => ['user_id = ?', active_user.id]).first
  #     answer = Transaction.refund(amount, trans.id)
  #     assert_equal answer[:code], Settings.error_codes.success, answer[:message]
  #     trans.reload
  #     assert_equal trans.refunded_amount, amount
  #     assert_equal trans.amount_available_to_refund, 0.0
  #     trans = Transaction.find(:all, :limit => 1, :order => 'created_at desc', 
  #                              :conditions => ['user_id = ? AND transaction_type = ?', active_user.id, 'credit']).first
  #     assert_equal trans.operation_type, Settings.operation_types.credit
  #     assert_equal trans.transaction_type, 'credit'
  #   end
  # end

  # test "Partial refund with Litle" do
  #   club_with_litle
  #   @credit_card = @credit_card_litle # overwrite credit card
  #   active_user = enroll_user(@litle_terms_of_membership, 100, false, @credit_card_litle)
  #   amount = @litle_terms_of_membership.installment_amount
  #   Timecop.travel(active_user.next_retry_bill_date) do
  #     answer = active_user.bill_membership
  #     active_user.reload
  #     assert_equal active_user.status, 'active'
  #     trans = Transaction.find(:all, :limit => 1, :conditions => ['user_id = ? and operation_type = ?', active_user.id, Settings.operation_types.membership_billing]).first
  #     refunded_amount = amount-0.34
  #     answer = Transaction.refund(refunded_amount, trans.id)
  #     assert_equal answer[:code], Settings.error_codes.success, answer[:message]
  #     trans.reload
  #     assert_equal trans.refunded_amount, refunded_amount
  #     assert_not_equal trans.amount_available_to_refund, 0.0
  #     trans = Transaction.find(:all, :limit => 1, :conditions => ['user_id = ? and operation_type = ?', active_user.id, Settings.operation_types.credit]).first
  #     assert_equal trans.operation_type, Settings.operation_types.credit
  #     assert_equal trans.transaction_type, 'credit'
  #   end
  # end

  # # Try billing an user's membership when he was previously SD for credit_card_expired before last billing for Litle
  # test "Try billing an user's membership when he was previously SD for credit_card_expired for Litle" do 
  #   @litle_club = FactoryGirl.create(:simple_club_with_litle_gateway)
  #   @litle_terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @litle_club.id)
  #   @credit_card_litle = FactoryGirl.build(:credit_card_american_express_litle)    

  #   active_user = create_active_user(@litle_terms_of_membership)
  #   active_merchant_stubs_litle(@sd_litle_expired_strategy.response_code, "decline stubbed", false)
  #   active_user.active_credit_card.update_attribute :token, @credit_card_litle.token

  #   active_user.bill_membership

  #   active_merchant_stubs_litle
  #   Timecop.travel(active_user.next_retry_bill_date) do
  #     old_year = active_user.active_credit_card.expire_year
  #     old_month = active_user.active_credit_card.expire_month
      
  #     assert_difference('Operation.count',6) do
  #       assert_difference('Transaction.count') do
  #         active_user.bill_membership
  #       end
  #     end
  #     active_user.reload
  #     assert_equal active_user.active_credit_card.expire_year, old_year+2
  #     assert_equal active_user.active_credit_card.expire_month, old_month
  #   end

  #   Timecop.travel(active_user.next_retry_bill_date) do
  #     old_year = active_user.active_credit_card.expire_year
  #     old_month = active_user.active_credit_card.expire_month
  #     active_user.bill_membership
  #     active_user.reload

  #     assert_equal active_user.active_credit_card.expire_year, old_year
  #     assert_equal active_user.active_credit_card.expire_month, old_month
  #   end
  # end

  # test "Try billing an user's membership when he was previously SD for credit_card_expired on different membership for Litle" do 
  #   @litle_club = FactoryGirl.create(:simple_club_with_litle_gateway)
  #   @litle_terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @litle_club.id)
  #   @litle_terms_of_membership_the_second = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @litle_club.id, :name =>"second_one")
  #   @credit_card_litle = FactoryGirl.build(:credit_card_american_express_litle)

  #   active_user = create_active_user(@litle_terms_of_membership)
  #   active_user.active_credit_card.update_attribute :token, @credit_card_litle.token

  #   active_merchant_stubs_litle(@sd_litle_expired_strategy.response_code, "decline stubbed", false)
  #   active_user.bill_membership
  #   active_user.change_terms_of_membership(@litle_terms_of_membership_the_second.id, "changing tom", 100)

  #   Timecop.travel(active_user.next_retry_bill_date) do
  #     active_merchant_stubs_litle

  #     old_year = active_user.active_credit_card.expire_year
  #     old_month = active_user.active_credit_card.expire_month
      
  #     assert_difference('Operation.count', 4) do
  #       assert_difference('Transaction.count') do
  #         active_user.bill_membership
  #       end
  #     end
  #     active_user.reload
  #     assert_equal active_user.active_credit_card.expire_year, old_year
  #     assert_equal active_user.active_credit_card.expire_month, old_month
  #   end
  # end

  test "should not update NBD after save the sale from monthly-tom to monthly-tom" do
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    user = enroll_user(@terms_of_membership, 0)
    nbd_initial = user.next_retry_bill_date

    assert_equal I18n.l(user.bill_date, :format => :only_date), I18n.l(Time.zone.now+@terms_of_membership.provisional_days.days, :format => :only_date)
    assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l(Time.zone.now+@terms_of_membership.provisional_days.days, :format => :only_date)
    user.save_the_sale @terms_of_membership2.id
    user.reload
    
    assert_equal nbd_initial, user.next_retry_bill_date
    assert_equal I18n.l(user.bill_date, :format => :only_date), I18n.l(Time.zone.now+@terms_of_membership2.provisional_days.days, :format => :only_date)
    assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l(nbd_initial, :format => :only_date)
    nbd = user.bill_date + @terms_of_membership2.installment_period.days

    Timecop.freeze( user.next_retry_bill_date ) do
      TasksHelpers.bill_all_members_up_today
      user.reload
      assert_equal user.bill_date, nbd 
      assert_equal user.next_retry_bill_date.to_date, nbd.to_date
    end
  end

  test "should not update NBD after save the sale from monthly-tom to yearly-tom" do
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership2 = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    user = enroll_user(@terms_of_membership, 0)
    nbd_initial = user.next_retry_bill_date

    assert_equal I18n.l(user.bill_date, :format => :only_date), I18n.l(Time.zone.now+@terms_of_membership.provisional_days.days, :format => :only_date)
    assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l(Time.zone.now+@terms_of_membership.provisional_days.days, :format => :only_date)
    user.save_the_sale @terms_of_membership2.id
    user.reload

    assert_equal nbd_initial, user.next_retry_bill_date
    assert_equal I18n.l(user.bill_date, :format => :only_date), I18n.l(Time.zone.now+@terms_of_membership2.provisional_days.days, :format => :only_date)
    assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l(nbd_initial, :format => :only_date)
    nbd = user.bill_date + @terms_of_membership2.installment_period.days

    Timecop.freeze( user.next_retry_bill_date ) do
      TasksHelpers.bill_all_members_up_today
      user.reload
      assert_equal user.bill_date, nbd 
      assert_equal user.next_retry_bill_date, nbd 
    end
  end

  test "should not update NBD after save the sale from yearly-tom to monthly-tom" do
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    @terms_of_membership2 = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    user = enroll_user(@terms_of_membership, 0)
    nbd_initial = Time.zone.now + user.terms_of_membership.provisional_days.days

    assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l(nbd_initial, :format => :only_date)
    user.save_the_sale @terms_of_membership2.id
    user.reload

    assert_equal I18n.l(user.bill_date, :format => :only_date), I18n.l(Time.zone.now+@terms_of_membership2.provisional_days.days, :format => :only_date)
    assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l(nbd_initial, :format => :only_date)
    nbd = user.bill_date + @terms_of_membership2.installment_period.days

    Timecop.freeze( user.next_retry_bill_date ) do
      TasksHelpers.bill_all_members_up_today
      user.reload
      assert_equal user.bill_date, nbd 
      assert_equal user.next_retry_bill_date, nbd 
    end
  end

  test "should not update NBD after save the sale from yearly-tom to yearly-tom" do
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    @terms_of_membership2 = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    user = enroll_user(@terms_of_membership, 0)
    nbd_initial = Time.zone.now + @terms_of_membership.provisional_days.days

    assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l(nbd_initial, :format => :only_date)
    user.save_the_sale @terms_of_membership2.id
    user.reload

    assert_equal I18n.l(nbd_initial, :format => :only_date), I18n.l(user.next_retry_bill_date, :format => :only_date)
    nbd = user.next_retry_bill_date + @terms_of_membership2.installment_period.days

    Timecop.freeze( user.next_retry_bill_date ) do
      TasksHelpers.bill_all_members_up_today
      user.reload
      assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l(nbd, :format => :only_date) 
    end
  end

  test "Should event bill an user, and also refund it." do
    user = enroll_user(@terms_of_membership, 0, false)
    amount = 200
    assert_difference("Transaction.count") do
      assert_difference("Operation.count") do
        user.no_recurrent_billing(amount,"testing event", "one-time")
      end
    end
    assert_not_nil user.transactions.find_by(operation_type: Settings.operation_types.no_recurrent_billing, transaction_type: 'sale')

    operation = Operation.last
    transaction = Transaction.last

    assert_equal(operation.description, "Member billed successfully $#{amount} Transaction id: #{transaction.id}. Reason: testing event")
    assert_equal(operation.operation_type, Settings.operation_types.no_recurrent_billing)
    assert_equal(transaction.full_label, "Sale : This transaction has been approved. Reason: testing event")
    assert transaction.success?

    answer = Transaction.refund(amount, transaction.id)
    assert_equal answer[:code], Settings.error_codes.success, answer[:message]
    transaction.reload
    assert_equal transaction.refunded_amount, amount
    assert_equal transaction.amount_available_to_refund, 0.0
    assert_not_nil user.transactions.find_by(operation_type: Settings.operation_types.credit, transaction_type: 'refund')
  end

  test "Should be able to do a full refund 9.97." do
    user = enroll_user(@terms_of_membership, 0, false)
    amount = 9.97

    user.no_recurrent_billing(amount,"testing event", "one-time")
    transaction = Transaction.last

    answer = Transaction.refund(amount, transaction.id)
    assert_equal answer[:code], Settings.error_codes.success, answer[:message]
    transaction.reload
    assert_equal transaction.refunded_amount.to_f, amount.to_f
    assert_equal transaction.amount_available_to_refund, 0.0
    user.reload
    assert_not_nil user.transactions.find_by(operation_type: Settings.operation_types.credit, transaction_type: 'refund')
  end

  test "Make no recurrent billing with user not expecting billing" do
    @terms_of_membership_not_expected_to_be_billed = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :is_payment_expected => false)
    user = enroll_user(@terms_of_membership_not_expected_to_be_billed, 0, false)
    amount = 200
    assert_difference("Transaction.count") do
      assert_difference("Operation.count") do
        user.no_recurrent_billing(amount,"testing event", "one-time")
      end
    end
  end

  test "Make check/cash payment with user not expecting billing" do
    @terms_of_membership_not_expected_to_be_billed = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :is_payment_expected => false)
    user = enroll_user(@terms_of_membership_not_expected_to_be_billed, 0, false)
    amount = 200
    assert_difference("Transaction.count",0) do
      assert_difference("Operation.count",0) do   #club_cash, manual_billing
        user.manual_billing(amount,"cash")
      end
    end
    assert_nil user.next_retry_bill_date
  end

  test "User with manual payment set should not be included on billing script" do
    user_manual_billing = enroll_user(@terms_of_membership)
    user_manual_billing.update_attribute :manual_payment, true
    nbd_manual = user_manual_billing.bill_date

    Timecop.travel(Time.zone.now + user_manual_billing.terms_of_membership.provisional_days.days) do
      assert_difference("Operation.count",0)do
        assert_difference("Transaction.count",0)do
          TasksHelpers.bill_all_members_up_today
        end
      end
    end
    assert_difference("Transaction.count",1)do
      user_manual_billing.manual_billing(100, 'cash_billing')
    end

    assert_equal user_manual_billing.next_retry_bill_date.to_date, nbd_manual.to_date
    user_manual_billing.update_attribute :manual_payment, false
    nbd_manual = user_manual_billing.bill_date
    Timecop.travel(Time.zone.now + user_manual_billing.terms_of_membership.provisional_days.days) do
      assert_difference("Operation.count",5)do
        assert_difference("Transaction.count",1)do
          TasksHelpers.bill_all_members_up_today
        end
      end
    end
  end

  test "save response on transaction when an exception take place when processing it" do
    user = enroll_user(@terms_of_membership, 0, true)
    user.update_attribute :next_retry_bill_date, Time.zone.now
    Transaction.any_instance.stubs(:process).raises("random error")

    assert_difference("Transaction.count")do
      user.bill_membership
    end
    assert_not_nil user.transactions.find_by(response_result: I18n.t('error_messages.airbrake_error_message'))
  end

  # Try billing an user's membership when he was previously SD for credit_card_expired before last billing for MeS
  test "Try billing an user's membership when he was previously SD for credit_card_expired for MeS" do 
    active_user = create_active_user(@terms_of_membership)
    active_merchant_stubs(@sd_mes_expired_strategy.response_code, "decline stubbed", false)
    active_user.bill_membership

    active_merchant_stubs
    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      
      assert_difference('Operation.count', 6) do
        assert_difference('Transaction.count') do
          active_user.bill_membership
        end
      end
      active_user.reload
      assert_equal active_user.active_credit_card.expire_year, old_year+2
      assert_equal active_user.active_credit_card.expire_month, old_month
    end

    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      active_user.bill_membership
      active_user.reload

      assert_equal active_user.active_credit_card.expire_year, old_year
      assert_equal active_user.active_credit_card.expire_month, old_month
    end
  end

  test "Try billing an user's membership when he was previously SD for credit_card_expired on different membership for MeS" do 
    active_user = create_active_user(@terms_of_membership)
    active_merchant_stubs(@sd_mes_expired_strategy, "decline stubbed", false)
    active_user.bill_membership
    active_user.change_terms_of_membership(@terms_of_membership_with_gateway_yearly.id, "changing tom", 100)

    active_merchant_stubs
    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      
      assert_difference('Operation.count', 4) do
        assert_difference('Transaction.count') do
          active_user.bill_membership
        end
      end
      active_user.reload
      assert_equal active_user.active_credit_card.expire_year, old_year
      assert_equal active_user.active_credit_card.expire_month, old_month
    end
  end

  test "Create and bill an user with installment period = X days or months at TOM" do 
    active_merchant_stubs

    @club = FactoryGirl.create(:simple_club_with_gateway_with_family)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)

    [6, 15, 365].each do |days|
      @club = FactoryGirl.create(:simple_club_with_gateway_with_family)
      @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :installment_period => days)
      @user = FactoryGirl.build(:user)
      user = enroll_user(@terms_of_membership)
      Timecop.travel(user.next_retry_bill_date) do
        TasksHelpers.bill_all_members_up_today
      end
      Timecop.travel(user.next_retry_bill_date) do
        TasksHelpers.bill_all_members_up_today
        user.reload
        nbd = user.next_retry_bill_date + days
        assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l(nbd, :format => :only_date)
      end
    end

    [1, 6, 24].each do |months|
      @club = FactoryGirl.create(:simple_club_with_gateway_with_family)
      @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :installment_period => (months*30.4166667).to_i )
      @user = FactoryGirl.build(:user)
      user = enroll_user(@terms_of_membership)

      Timecop.travel(user.next_retry_bill_date) do
        TasksHelpers.bill_all_members_up_today
      end
      Timecop.travel(user.next_retry_bill_date) do
        nbd = user.next_retry_bill_date + (months*30.4166667).to_i.days
        TasksHelpers.bill_all_members_up_today
        user.reload
        assert_equal I18n.l(user.next_retry_bill_date, :format => :only_date), I18n.l(nbd, :format => :only_date)
      end      
    end

    @club.update_attribute :family_memberships_allowed, false
  end

  ############################################################################
  ############ CLUB CASH ###############
  ############################################################################


  test "Create an user with initial_club_cash_amount and club_cash_installment_amount like 0 and skip_first_club_cash set as false" do
    @terms_of_membership.update_attribute :skip_first_club_cash, false
    @terms_of_membership.update_attribute :club_cash_installment_amount, 0
    @terms_of_membership.update_attribute :initial_club_cash_amount, 0

    user = enroll_user(@terms_of_membership, 0)
    assert_equal user.club_cash_amount, 0

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount
    assert_difference("Operation.count",3) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",0) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 0

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount

    assert_difference("Operation.count",4) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",0) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 0
  end

  test "Create an user with initial_club_cash_amount and club_cash_installment_amount like 0 and skip_first_club_cash set as true" do
    @terms_of_membership.update_attribute :skip_first_club_cash, true
    @terms_of_membership.update_attribute :club_cash_installment_amount, 0
    @terms_of_membership.update_attribute :initial_club_cash_amount, 0

    user = enroll_user(@terms_of_membership, 0)
    assert_equal user.club_cash_amount, 0

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount
    assert_difference("Operation.count",3) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",0) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 0

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount

    assert_difference("Operation.count",4) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",0) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 0
  end

  test "Create an user with initial_club_cash_amount = X, club_cash_installment_amount = 0 and skip_first_club_cash set = false" do
    @terms_of_membership.update_attribute :skip_first_club_cash, false
    @terms_of_membership.update_attribute :club_cash_installment_amount, 0
    @terms_of_membership.update_attribute :initial_club_cash_amount, 100

    user = enroll_user(@terms_of_membership, 0)
    assert_equal user.club_cash_amount, 100 

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount
    assert_difference("Operation.count",3) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",0) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 100

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount

    assert_difference("Operation.count",4) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",0) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 100  
  end

  test "Create an user with initial_club_cash_amount = X, club_cash_installment_amount = 0 and skip_first_club_cash set = true" do
    @terms_of_membership.update_attribute :skip_first_club_cash, true
    @terms_of_membership.update_attribute :club_cash_installment_amount, 0
    @terms_of_membership.update_attribute :initial_club_cash_amount, 100

    user = enroll_user(@terms_of_membership, 0)
    assert_equal user.club_cash_amount, 100 

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount
    assert_difference("Operation.count",3) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",0) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 100

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount

    assert_difference("Operation.count",4) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",0) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 100
  end

  test "Create an user with initial_club_cash_amount = X, club_cash_installment_amount = X and skip_first_club_cash set = false" do
    @terms_of_membership.update_attribute :skip_first_club_cash, true
    @terms_of_membership.update_attribute :club_cash_installment_amount, 50
    @terms_of_membership.update_attribute :initial_club_cash_amount, 100

    user = enroll_user(@terms_of_membership, 0)
    assert_equal user.club_cash_amount, 100 

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount
    assert_difference("Operation.count",3) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",0) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 100

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount

    assert_difference("Operation.count",5) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",1) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 150
  end

  test "Create an user with initial_club_cash_amount = X, club_cash_installment_amount = X and skip_first_club_cash set = true" do
    @terms_of_membership.update_attribute :skip_first_club_cash, true
    @terms_of_membership.update_attribute :club_cash_installment_amount, 50
    @terms_of_membership.update_attribute :initial_club_cash_amount, 100

    user = enroll_user(@terms_of_membership, 0)
    assert_equal user.club_cash_amount, 100 

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount

    assert_difference("Operation.count",3) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",0) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 100

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount

    assert_difference("Operation.count",5) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",1) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 150  
  end

  test "Create an user with initial_club_cash_amount = 0, club_cash_installment_amount = X and skip_first_club_cash set = false" do
    @terms_of_membership.update_attribute :skip_first_club_cash, false
    @terms_of_membership.update_attribute :club_cash_installment_amount, 50
    @terms_of_membership.update_attribute :initial_club_cash_amount, 0

    user = enroll_user(@terms_of_membership, 0) 
    assert_equal user.club_cash_amount, 0 

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount
    assert_difference("Operation.count",4) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",1) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 50

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount

    assert_difference("Operation.count",5) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",1) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 100
  end

  test "Create an user with initial_club_cash_amount = 0, club_cash_installment_amount = X and skip_first_club_cash set = true" do
    @terms_of_membership.update_attribute :skip_first_club_cash, true
    @terms_of_membership.update_attribute :club_cash_installment_amount, 50
    @terms_of_membership.update_attribute :initial_club_cash_amount, 0

    user = enroll_user(@terms_of_membership, 0) 
    assert_equal user.club_cash_amount, 0 

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount
    assert_difference("Operation.count",3) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",0) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 0

    user.update_attribute :next_retry_bill_date, Time.zone.now
    club_cash = user.club_cash_amount

    assert_difference("Operation.count",5) do
      assert_difference("Transaction.count")do
        assert_difference("ClubCashTransaction.count",1) do
          user.bill_membership
        end
      end
    end
    user.reload
    assert_equal user.club_cash_amount, 50
  end

  test "Should not let refunds on transactions with different pgc" do
    previous_pgc = @club.payment_gateway_configurations.first

    active_user = create_active_user(@terms_of_membership)
    amount = @terms_of_membership.installment_amount
    active_user.update_attribute :next_retry_bill_date, Time.zone.now
    answer = active_user.bill_membership

    @club.payment_gateway_configurations.first.delete
    old_pgc = FactoryGirl.create(:litle_payment_gateway_configuration, :club_id => @club.id)
    active_user.reload
    assert_equal active_user.status, 'active'

    assert_difference('Operation.count', 0) do
      assert_difference('Transaction.count', 0) do
        assert_difference('Communication.count', 0) do
          trans = active_user.transactions.last
          answer = Transaction.refund(amount, trans.id)
        end 
      end
    end
  end


#####################################################
######  AUTHORIZED NET ##############################
#####################################################

  # Tets Authorize net transactions
  def club_with_authorize_net
    @authorize_net_club = FactoryGirl.create(:simple_club_with_authorize_net_gateway)
    @authorize_net_terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @authorize_net_club.id)
    @credit_card_authorize_net = FactoryGirl.build(:credit_card_american_express_authorize_net)
  end

  test "Bill membership with Authorize net" do
    club_with_authorize_net
    active_user = enroll_user(@authorize_net_terms_of_membership, 100, false, @credit_card_authorize_net)
    amount = @authorize_net_terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      answer = active_user.bill_membership
      active_user.reload
      assert_equal active_user.status, 'active'
    end
  end

  test "Enroll with Authorize net" do
    club_with_authorize_net
    active_merchant_stubs_auth_net
    enroll_user(@authorize_net_terms_of_membership, 23, false, @credit_card_authorize_net)
  end

  # test "Full refund with Authorize net" do
  #   club_with_authorize_net
  #   active_member = enroll_member(@authorize_net_terms_of_membership, 100, false, @credit_card_authorize_net)
  #   amount = @authorize_net_terms_of_membership.installment_amount
  #   Timecop.travel(active_member.next_retry_bill_date) do
  #     answer = active_member.bill_membership
  #     active_member.reload
  #     assert_equal active_member.status, 'active'
  #     trans = active_member.transactions.last
  #     answer = Transaction.refund(amount, trans.id)
  #     assert_equal answer[:code], 3, answer[:message] # refunds cant be processed on Auth.net test env
  #   end
  #   assert_equal Transaction.find_by_transaction_type('credit').operation_type, Settings.operation_types.credit
  # end

  # test "Partial refund with Authorize net" do
  #   club_with_authorize_net
  #   active_member = enroll_member(@authorize_net_terms_of_membership, 100, false, @credit_card_authorize_net)
  #   amount = @authorize_net_terms_of_membership.installment_amount
  #   Timecop.travel(active_member.next_retry_bill_date) do
  #     answer = active_member.bill_membership
  #     active_member.reload
  #     assert_equal active_member.status, 'active'
  #     trans = Transaction.find(:all, :limit => 1, :order => 'created_at desc', :conditions => ['member_id = ?', active_member.id]).first
  #     refunded_amount = amount-0.34
  #     answer = Transaction.refund(refunded_amount, trans.id)
  #     assert_equal answer[:code], 3, answer[:message] # refunds cant be processed on Auth.net test env
  #     trans = Transaction.find(:all, :limit => 1, :order => 'created_at desc', :conditions => ['member_id = ?', active_member.id]).first
  #     assert_equal trans.operation_type, Settings.operation_types.credit
  #     assert_equal trans.transaction_type, 'refund'
  #   end
  # end

  # Try billing an user's membership when he was previously SD for credit_card_expired before last billing for Auth.net
  test "Try billing an user's membership when he was previously SD for credit_card_expired for Auth.net" do 
    active_merchant_stubs_auth_net
    @authorize_net_club = FactoryGirl.create(:simple_club_with_authorize_net_gateway)
    @authorize_net_terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @authorize_net_club.id)
    @credit_card_authorize_net = FactoryGirl.build(:credit_card_american_express_authorize_net, :token => "tzNduuh2DRQT7FXUILDl3Q==")

    active_user = create_active_user(@authorize_net_terms_of_membership)
    active_merchant_stubs_auth_net(@sd_auth_net_expired_strategy.response_code, "decline stubbed", false)
    active_user.active_credit_card.update_attribute :token, @credit_card_authorize_net.token

    active_user.bill_membership
    Timecop.travel(active_user.next_retry_bill_date) do
      active_merchant_stubs_auth_net
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      assert_difference('Operation.count', 4) do
        assert_difference('Transaction.count') do
          active_user.bill_membership
        end
      end
      active_user.reload
      assert_equal active_user.active_credit_card.expire_year, old_year+2
      assert_equal active_user.active_credit_card.expire_month, old_month
    end

    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      active_user.bill_membership
      active_user.reload
      assert_equal active_user.active_credit_card.expire_year, old_year
      assert_equal active_user.active_credit_card.expire_month, old_month
    end
  end

  test "Try billing an user's membership when he was previously SD for credit_card_expired on different membership for Auth.net" do 
    active_merchant_stubs_auth_net
    @authorize_net_club = FactoryGirl.create(:simple_club_with_authorize_net_gateway)
    @authorize_net_terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @authorize_net_club.id)
    @authorize_net_terms_of_membership_second = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @authorize_net_club.id, :name =>"second_one")
    @credit_card_authorize_net = FactoryGirl.build(:credit_card_american_express_authorize_net)
    
    active_user = enroll_user(@authorize_net_terms_of_membership, 0, false, @credit_card_authorize_net)
    active_user.next_retry_bill_date = Time.zone.now

    active_merchant_stubs_auth_net(@sd_auth_net_expired_strategy.response_code, "decline stubbed", false)
    active_user.bill_membership
    active_user.change_terms_of_membership(@authorize_net_terms_of_membership_second.id, "changing tom", 100)

    Timecop.travel(active_user.next_retry_bill_date) do
      active_merchant_stubs_auth_net

      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      
      assert_difference('Operation.count', 3) do
        assert_difference('Transaction.count') do
          active_user.bill_membership
        end
      end
      active_user.reload
      assert_equal active_user.active_credit_card.expire_year, old_year
      assert_equal active_user.active_credit_card.expire_month, old_month
    end
  end

######################################################
#######  FIRST DATA ##################################
######################################################

  # Tets FirstData transactions
  def club_with_first_data
    @first_data_club = FactoryGirl.create(:simple_club_with_first_data_gateway)
    @first_data_terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @first_data_club.id)
    @credit_card_first_data = FactoryGirl.build(:credit_card_visa_first_data)
  end

  test "Enroll with FirstData" do
    club_with_first_data
    enroll_user(@first_data_terms_of_membership, 23, false, @credit_card_first_data)
  end

  test "Bill membership with FirstData" do
    club_with_first_data
    active_user = enroll_user(@first_data_terms_of_membership, 100, false, @credit_card_first_data)
    amount = @first_data_terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      answer = active_user.bill_membership
      active_user.reload
      assert_equal active_user.status, 'active'
    end
  end

  test "Full refund with FirstData" do
    club_with_first_data
    active_user = enroll_user(@first_data_terms_of_membership, 100, false, @credit_card_first_data)
    amount = @first_data_terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      answer = active_user.bill_membership
      active_user.reload
      assert_equal active_user.status, 'active'
      trans = active_user.transactions.last
      answer = Transaction.refund(amount, trans.id)
      assert_equal answer[:code], "000", answer[:message]
    end
    assert_equal Transaction.find_by_transaction_type('refund').operation_type, Settings.operation_types.credit
  end

  test "Partial refund with FirstData" do
    club_with_first_data
    active_user = enroll_user(@first_data_terms_of_membership, 100, false, @credit_card_first_data)
    amount = @first_data_terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      answer = active_user.bill_membership
      active_user.reload
      assert_equal active_user.status, 'active'
      trans = active_user.transactions.find_by(transaction_type: 'sale')
      refunded_amount = amount-0.34
      answer = Transaction.refund(refunded_amount, trans.id)
      assert_equal answer[:code], "000", answer[:message] # refunds cant be processed on Auth.net test env
      assert_equal Transaction.where("user_id = ? and operation_type = ? and transaction_type = 'refund'", active_user.id, Settings.operation_types.credit).count, 1
    end
  end

  # Try billing an user's membership when he was previously SD for credit_card_expired before last billing for FirstData
  test "Try billing an user's membership when he was previously SD for credit_card_expired for FirstData" do 
    club_with_first_data
    active_user = create_active_user(@first_data_terms_of_membership)
    active_card = active_user.active_credit_card
    
    active_merchant_stubs_first_data(@sd_first_data_expired_strategy.response_code, "decline stubbed", false)
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
    end

    active_merchant_stubs_first_data
    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      assert_difference('Operation.count', 4) do
        assert_difference('Transaction.count') do
          active_user.bill_membership
        end
      end
      active_user.reload
      assert_equal active_user.active_credit_card.expire_year, old_year+2
      assert_equal active_user.active_credit_card.expire_month, old_month
    end

    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      active_user.bill_membership
      active_user.reload

      assert_equal active_user.active_credit_card.expire_year, old_year
      assert_equal active_user.active_credit_card.expire_month, old_month
    end
  end

  test "Try billing an user's membership when he was previously SD for credit_card_expired on different membership for FirstData" do 
    club_with_first_data
    @first_data_terms_of_membership_second = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @first_data_club.id, :name =>"second_one")
    active_user = enroll_user(@first_data_terms_of_membership, 100, false, @credit_card_first_data)
    active_card = active_user.active_credit_card

    active_merchant_stubs_first_data(@sd_first_data_expired_strategy.response_code, "decline stubbed", false)
    Timecop.travel(active_user.next_retry_bill_date) do
      active_user.bill_membership
    end
    active_user.change_terms_of_membership(@first_data_terms_of_membership_second.id, "changing tom", 100)

    active_merchant_stubs_first_data
    Timecop.travel(active_user.next_retry_bill_date) do
      old_year = active_user.active_credit_card.expire_year
      old_month = active_user.active_credit_card.expire_month
      
      assert_difference('Operation.count', 3) do
        assert_difference('Transaction.count') do
          active_user.bill_membership
        end
      end
      active_user.reload
      assert_equal active_user.active_credit_card.expire_year, old_year
      assert_equal active_user.active_credit_card.expire_month, old_month
    end
  end

  test "Create an user and make sure we are sending membership_renewal communication each membership billing except the first one" do
    user = enroll_user(@terms_of_membership, 0)

    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Communication.count',1) do
        user.bill_membership
      end
    end
    assert_not_nil Communication.find_by_template_type "membership_bill"
    assert_nil Communication.find_by_template_type "membership_renewal"
    
    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Communication.count',2) do
        user.bill_membership
      end
    assert_not_nil Communication.find_by_template_type "membership_renewal"
    assert_not_nil Communication.find_by_template_type "membership_bill"
    end
  end

######################################################
#######  STRIPE ######################################
######################################################

  # Tets Stripe transactions
  def club_with_stripe
    @stripe_club = FactoryGirl.create(:simple_club_with_stripe_gateway)
    @stripe_terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @stripe_club.id)
    @credit_card_stripe = FactoryGirl.build(:credit_card_visa_stripe)
    active_merchant_stubs_stripe
  end

  test "Enroll with Stripe" do
    club_with_stripe
    enroll_user(@stripe_terms_of_membership, 23, false, @credit_card_stripe)
  end

  test "Bill membership with Stripe" do
    club_with_stripe
    active_user = enroll_user(@stripe_terms_of_membership, 100, false, @credit_card_stripe)
    amount = @stripe_terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      answer = active_user.bill_membership
      active_user.reload
      assert_equal active_user.status, 'active'
    end
  end

  test "Full refund with Stripe" do
    club_with_stripe
    active_user = enroll_user(@stripe_terms_of_membership, 100, false, @credit_card_stripe)
    amount = @stripe_terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      answer = active_user.bill_membership
      active_user.reload
      assert_equal active_user.status, 'active'
      trans = active_user.transactions.last
      answer = Transaction.refund(amount, trans.id)
      assert_equal answer[:code], "000", answer[:message]
    end
    assert_equal Transaction.find_by_transaction_type('refund').operation_type, Settings.operation_types.credit
  end

  test "Partial refund with Stripe" do
    club_with_stripe
    active_user = enroll_user(@stripe_terms_of_membership, 100, false, @credit_card_stripe)
    amount = @stripe_terms_of_membership.installment_amount
    Timecop.travel(active_user.next_retry_bill_date) do
      answer = active_user.bill_membership
      active_user.reload
      assert_equal active_user.status, 'active'
      trans = active_user.transactions.find_by(transaction_type: 'sale')
      refunded_amount = amount-0.34
      answer = Transaction.refund(refunded_amount, trans.id)
      assert_equal answer[:code], "000", answer[:message] # refunds cant be processed on Auth.net test env
      assert_equal Transaction.where("user_id = ? and operation_type = ? and transaction_type = 'refund'", active_user.id, Settings.operation_types.credit).count, 1
    end
  end
end