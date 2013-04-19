require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    @current_agent = FactoryGirl.create(:agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @terms_of_membership_with_gateway_yearly = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    @member = FactoryGirl.build(:member)
    @credit_card = FactoryGirl.build(:credit_card)
    @sd_strategy = FactoryGirl.create(:soft_decline_strategy)
    @hd_strategy = FactoryGirl.create(:hard_decline_strategy)
    FactoryGirl.create(:without_grace_period_decline_strategy_monthly)
    FactoryGirl.create(:without_grace_period_decline_strategy_yearly)
  end

  def enroll_member(tom)
    answer = Member.enroll(tom, @current_agent, 23, 
      { first_name: @member.first_name,
        last_name: @member.last_name, address: @member.address, city: @member.city, gender: 'M',
        zip: @member.zip, state: @member.state, email: @member.email, type_of_phone_number: @member.type_of_phone_number,
        phone_country_code: @member.phone_country_code, phone_area_code: @member.phone_area_code,
        type_of_phone_number: 'Home', phone_local_number: @member.phone_local_number, country: 'US', 
        product_sku: Settings.kit_card_product }, 
      { number: @credit_card.number, 
        expire_year: @credit_card.expire_year, expire_month: @credit_card.expire_month })

    assert (answer[:code] == Settings.error_codes.success), answer[:message]

    member = Member.find(answer[:member_id])
    assert_not_nil member
    assert_equal member.status, 'provisional'
    member
  end

  test "save operation" do
    assert_difference('Operation.count') do
      Auditory.audit(@current_agent, nil, "test")
    end
  end

  test "Enrollment with approval" do
    @tom_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval, :club_id => @club.id)
    active_merchant_stubs
    assert_difference('Operation.count',1) do
      assert_no_difference('Fulfillment.count') do
        answer = Member.enroll(@tom_approval, @current_agent, 23, 
          { first_name: @member.first_name,
            last_name: @member.last_name, address: @member.address, city: @member.city, gender: 'M',
            zip: @member.zip, state: @member.state, email: @member.email, type_of_phone_number: @member.type_of_phone_number,
            phone_country_code: @member.phone_country_code, phone_area_code: @member.phone_area_code,
            type_of_phone_number: 'Home', phone_local_number: @member.phone_local_number, country: 'US', :product_sku => Settings.kit_card_product }, 
          { number: @credit_card.number, 
            expire_year: @credit_card.expire_year, expire_month: @credit_card.expire_month })
        assert (answer[:code] == Settings.error_codes.success), answer[:message]
        member = Member.find(answer[:member_id])
        assert_not_nil member
        assert_not_nil member.join_date, "join date should not be nil"
        assert_nil member.bill_date, "bill date should be nil"
        assert_equal 'applied', member.status
      end
    end
  end

  test "Enrollment without approval" do
    active_merchant_stubs
    assert_difference('Operation.count',1) do
      assert_difference('Fulfillment.count') do
        member = enroll_member(@terms_of_membership)
        assert_not_nil member.next_retry_bill_date, "NBD should not be nil"
        assert_not_nil member.join_date, "join date should not be nil"
        assert_not_nil member.bill_date, "bill date should not be nil"
        assert_equal member.recycled_times, 0, "recycled_times should be 0"
      end
    end
  end

  test "controlled refund (refund completely a transaction)" do
    active_member = create_active_member(@terms_of_membership)
    amount = @terms_of_membership.installment_amount
    answer = active_member.bill_membership
    active_member.reload
    assert_equal active_member.status, 'active'
    assert_difference('Operation.count', +2) do
      assert_difference('Transaction.count') do
        assert_difference('Communication.count') do
          trans = active_member.transactions.last
          answer = Transaction.refund(amount, trans)
          assert_equal answer[:code], Settings.error_codes.success, answer[:message]
          trans.reload
          assert_equal trans.refunded_amount, amount
          assert_equal trans.amount_available_to_refund, 0.0
        end
      end
    end
  end


  test "Monthly member billed 24 months" do 
    active_merchant_stubs

    member = enroll_member(@terms_of_membership)
    nbd = member.bill_date

    # bill members the day before trial days expires. Member should not be billed
    Timecop.travel(Time.zone.now + member.terms_of_membership.provisional_days.days - 2.days) do
      Member.bill_all_members_up_today
      member.reload
      assert_equal nbd, member.bill_date
      assert_equal 0, member.quota
    end

    # bill members the day trial days expires. Member should be billed
    Timecop.travel(Time.zone.now + member.terms_of_membership.provisional_days.days) do
      Member.bill_all_members_up_today
      member.reload
      nbd = nbd + eval(member.terms_of_membership.installment_type)
      assert_equal nbd, member.next_retry_bill_date
      assert_equal member.bill_date, member.next_retry_bill_date
      assert_equal 1, member.quota
    end

    next_month = Time.zone.now + member.terms_of_membership.provisional_days.days
    1.upto(24) do |time|
      Timecop.travel(next_month + time.month) do
        Member.bill_all_members_up_today
        member.reload
        nbd = nbd + eval(member.terms_of_membership.installment_type)
        assert_equal nbd, member.next_retry_bill_date
        assert_equal member.bill_date, member.next_retry_bill_date
        assert_equal member.quota, time+1
        assert_equal member.recycled_times, 0
      end
    end
  end

  test "Yearly member billed 4 years" do 
    active_merchant_stubs

    # if we use 5 years take care to have a credit card that does not get expired.
    @credit_card.expire_year = Time.zone.now.year + 7

    member = enroll_member(@terms_of_membership_with_gateway_yearly)
    nbd = member.bill_date

    # bill members the day before trial days expires. Member should not be billed
    Timecop.travel(Time.zone.now + member.terms_of_membership.provisional_days.days - 2.days) do
      Member.bill_all_members_up_today
      member.reload
      assert_equal nbd, member.bill_date
      assert_equal 0, member.quota
    end

    # bill members the day trial days expires. Member should be billed
    Timecop.travel(Time.zone.now + member.terms_of_membership.provisional_days.days) do
      Member.bill_all_members_up_today
      member.reload
      nbd = nbd + eval(member.terms_of_membership.installment_type)
      assert_equal nbd, member.next_retry_bill_date
      assert_equal member.bill_date, member.next_retry_bill_date
      assert_equal 12, member.quota
    end

    next_year = Time.zone.now
    2.upto(5) do |time|
      Timecop.travel(next_year + time.years) do
        Member.bill_all_members_up_today
        member.reload
        nbd = nbd + eval(member.terms_of_membership.installment_type)
        assert_equal nbd, member.next_retry_bill_date
        assert_equal member.bill_date, member.next_retry_bill_date
        assert_equal member.quota, time*12
        assert_equal member.recycled_times, 0
      end
    end
  end



  ######################################
  ############ DECLINE ###################
  test "Monthly member SD until gets HD" do 
    active_merchant_stubs_store
    active_merchant_stubs

    member = enroll_member(@terms_of_membership)
    nbd = member.bill_date
    bill_date = member.bill_date
    
    active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false)

    # bill members the day trial days expires. Member should be billed but SD'd
    Timecop.travel(Time.zone.now + member.terms_of_membership.provisional_days.days) do
      Member.bill_all_members_up_today
      member.reload
      nbd = nbd + @sd_strategy.days.days
      assert_equal nbd.to_date, member.next_retry_bill_date.to_date
      assert_equal bill_date, member.bill_date
      assert_not_equal member.bill_date, member.next_retry_bill_date
      assert_equal 0, member.quota
      assert_equal 1, member.recycled_times
    end

    # SD retries
    2.upto(15) do |time|
      Timecop.travel(nbd) do
        Member.bill_all_members_up_today
        member.reload
        if member.next_retry_bill_date.nil?
          cancel_date = member.cancel_date
          assert_equal cancel_date, member.cancel_date
          assert_nil member.next_retry_bill_date
          assert_nil member.bill_date
          assert_not_nil member.cancel_date
          assert_equal 0, member.quota
          assert_equal 0, member.recycled_times
          assert_equal 1, member.operations.find_all_by_operation_type(Settings.operation_types.membership_billing_hard_decline).count
        else
          nbd = nbd + @sd_strategy.days.days
          assert_equal nbd, member.next_retry_bill_date
          assert_equal bill_date, member.bill_date
          assert_not_equal member.bill_date, member.next_retry_bill_date
          assert_equal 0, member.quota
          assert_equal time, member.recycled_times
          assert_equal time, member.operations.find_all_by_operation_type(Settings.operation_types.membership_billing_soft_decline).count
        end
      end
    end
  end

  test "Billing with SD is re-scheduled" do 
    active_merchant_stubs_store
    assert_difference('Operation.count', 2) do
      assert_difference('Transaction.count') do
        active_member = create_active_member(@terms_of_membership)
        active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false)
        nbd = active_member.bill_date
        answer = active_member.bill_membership
        active_member.reload
        assert !active_member.lapsed?, "member cant be lapsed"
        assert_equal active_member.next_retry_bill_date.to_date, @sd_strategy.days.days.from_now.to_date, "next_retry_bill_date should #{@sd_strategy.days.days.from_now}"
        assert_equal active_member.bill_date, nbd, "bill_date should not be touched #{nbd}"
        assert_equal active_member.recycled_times, 1, "recycled_times should be 1"
      end
    end
  end

  test "Billing with grace period disable on tom and missing CC" do
    active_member = create_active_member(@terms_of_membership, :active_member_without_cc)
    nbd = active_member.bill_date
    assert_difference('Operation.count', 5) do
      assert_difference('Communication.count', 2) do
        assert_difference('Transaction.count', 1) do
          answer = active_member.bill_membership
          active_member.reload
          assert_equal active_member.status, "lapsed"
          assert (answer[:code] != Settings.error_codes.success), "#{answer[:code]} cant be 000 (success)"
        end
      end
    end
  end

  test "Billing with SD reaches the recycle limit, and HD cancels member." do 
    active_merchant_stubs_store
    assert_difference('Operation.count', 5) do
      assert_difference('Communication.count', 2) do
        active_member = create_active_member(@terms_of_membership)
        active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false) 
        amount = @terms_of_membership.installment_amount
        active_member.recycled_times = 4
        active_member.save
        answer = active_member.bill_membership
        active_member.reload
        assert (answer[:code] != Settings.error_codes.success), "#{answer[:code]} cant be 000 (success)"
        assert active_member.lapsed?, "member should be lapsed after recycle limit is reached"
        assert_nil active_member.next_retry_bill_date, "next_retry_bill_date should be nil"
        assert_nil active_member.bill_date, "bill_date should be nil"
        assert_equal active_member.recycled_times, 0, "recycled_times should be 0"
      end
    end
  end

  test "Billing with HD cancels member" do 
    active_merchant_stubs_store
    assert_difference('Operation.count', 5) do
      assert_difference('Communication.count', 2) do
        active_member = create_active_member(@terms_of_membership)
        active_merchant_stubs(@hd_strategy.response_code, "decline stubbed", false)
        amount = @terms_of_membership.installment_amount
        answer = active_member.bill_membership
        active_member.reload
        assert active_member.lapsed?, "member should be lapsed after HD"
        assert_nil active_member.next_retry_bill_date, "next_retry_bill_date should be nil"
        assert_nil active_member.bill_date, "bill_date should be nil"
        assert_equal active_member.recycled_times, 0, "recycled_times should be 0"
      end
    end
  end

  test "Billing declined, but there is no decline rule. Send email" do 
    active_merchant_stubs_store
    active_member = create_active_member(@terms_of_membership)
    active_merchant_stubs("34234", "decline stubbed", false) 
    amount = @terms_of_membership.installment_amount
    answer = active_member.bill_membership
    active_member.reload
    assert_equal active_member.next_retry_bill_date.to_date, (Time.zone.now + eval(Settings.next_retry_on_missing_decline)).to_date, "Next retry bill date incorrect"
  end
  ############################################

  # TODO: how do we stub faraday?
  test "Chargeback processing should create transaction, blacklist and cancel the member" do
    active_member = create_active_member(@terms_of_membership)
    transaction = FactoryGirl.create(:transaction, member: active_member, terms_of_membership: @terms_of_membership)
    answer = { :body => '"Merchant Id","DBA Name","Control Number","Incoming Date","Card Number","Reference Number",' + 
      '"Tran Date","Tran Amount","Trident Tran ID","Purchase ID","Client Ref Num","Auth Code","Adj Date",' +
      '"Adj Ref Num","Reason","First Time","Reason Code","CB Ref Num","Terminal ID"\n' +
      '"941000110030",""SAC*AO ADVENTURE CLUB"","2890810","07/26/2012","'+active_member.credit_cards.first.number.to_s+
      '","25247702125003734750438",'+
      '"05/03/2012","84.0","'+transaction.response_transaction_id+'","'+active_member.id.to_s+'",""'+
      active_member.id.to_s+'"","00465Z",""07/27/2012-""' +
      ',""00373475043"",""No Cardholder Authorization"","Y","4837","2206290194",""94100011003000000002""' }

    # assert_difference('Transaction', 1) do 
    #   PaymentGatewayConfiguration.process_mes_chargebacks('development')
    #   assert_equal active_member.blacklisted, true
    #   assert_equal active_member.status, "cancel"
    # end
  end


end
