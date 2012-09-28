require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    @current_agent = FactoryGirl.create(:agent)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway)
    @member = FactoryGirl.build(:member)
    @credit_card = FactoryGirl.build(:credit_card)
    @sd_strategy = FactoryGirl.create(:soft_decline_strategy)
    @hd_strategy = FactoryGirl.create(:hard_decline_strategy)
    @use_active_merchant = false
  end

  test "save operation" do
    assert_difference('Operation.count') do
      Auditory.audit(@current_agent, nil, "test")
    end
  end

  test "Enrollment with approval" do
    @tom_approval = FactoryGirl.create(:terms_of_membership_with_gateway_needs_approval)
    active_merchant_stubs unless @use_active_merchant
    assert_difference('Operation.count',1) do
      assert_no_difference('Fulfillment.count') do
        answer = Member.enroll(@tom_approval, @current_agent, 23, 
          { first_name: @member.first_name,
            last_name: @member.last_name, address: @member.address, city: @member.city, gender: 'M',
            zip: @member.zip, state: @member.state, email: @member.email, type_of_phone_number: @member.type_of_phone_number,
            phone_country_code: @member.phone_country_code, phone_area_code: @member.phone_area_code,
            type_of_phone_number: 'Home', phone_local_number: @member.phone_local_number, country: 'US' }, 
          { number: @credit_card.number, 
            expire_year: @credit_card.expire_year, expire_month: @credit_card.expire_month })
        assert (answer[:code] == Settings.error_codes.success), answer[:message]
        member = Member.find_by_uuid(answer[:member_id])
        assert_not_nil member
        assert_not_nil member.join_date, "join date should not be nil"
        assert_nil member.bill_date, "bill date should be nil"
        assert_equal 'applied', member.status
      end
    end
  end

  test "Enrollment without approval" do
    active_merchant_stubs unless @use_active_merchant
    assert_difference('Operation.count',1) do
      assert_difference('Fulfillment.count') do
        answer = Member.enroll(@terms_of_membership, @current_agent, 23, 
          { first_name: @member.first_name,
            last_name: @member.last_name, address: @member.address, city: @member.city, gender: 'M',
            zip: @member.zip, state: @member.state, email: @member.email, type_of_phone_number: @member.type_of_phone_number,
            phone_country_code: @member.phone_country_code, phone_area_code: @member.phone_area_code,
            type_of_phone_number: 'Home', phone_local_number: @member.phone_local_number, country: 'US', 
            product_sku: 'Circlet' }, 
          { number: @credit_card.number, 
            expire_year: @credit_card.expire_year, expire_month: @credit_card.expire_month })

        assert (answer[:code] == Settings.error_codes.success), answer[:message]
        member = Member.find_by_uuid(answer[:member_id])
        assert_not_nil member
        assert_equal member.status, 'provisional'
        assert_not_nil member.next_retry_bill_date, "NBD should not be nil"
        assert_not_nil member.join_date, "join date should not be nil"
        assert_not_nil member.bill_date, "bill date should not be nil"
        assert_equal member.recycled_times, 0, "recycled_times should be 0"
      end
    end
  end

  test "controlled refund (refund completely a transaction)" do
    active_merchant_stubs unless @use_active_merchant
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


  # AGREGAR TEST:
  # - member monthly bill, NBD change
  # - member yearly bill, NBD change
  # - member bill SD, NBD change , bill_date not change, recycled_times increment
  # - member bill HD, Cancellation => envio mail

  ######################################
  ############ DECLINE ###################
  test "Billing with SD is re-scheduled" do 
    active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false)
    assert_difference('Operation.count') do
      assert_difference('Transaction.count') do
        active_member = create_active_member(@terms_of_membership)
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
  test "Billing with grace period enabled on tom and missing CC" do
    @grace_strategy = FactoryGirl.create(:grace_period_decline_strategy)
    active_member = create_active_member(@terms_of_membership, :active_member_without_cc)
    nbd = active_member.bill_date
    @terms_of_membership.grace_period = 15
    @terms_of_membership.save
    answer = active_member.bill_membership
#TODO

  end
  test "Billing with grace period disable on tom and missing CC" do
    active_member = create_active_member(@terms_of_membership, :active_member_without_cc)
    nbd = active_member.bill_date
    @terms_of_membership.grace_period = 0
    @terms_of_membership.save
    answer = active_member.bill_membership
#TODO

  end
  test "Billing with SD reaches the recycle limit, and HD cancels member." do 
    active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false) 
    assert_difference('Operation.count', +3) do
      active_member = create_active_member(@terms_of_membership)
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

  test "Billing with HD cancels member" do 
    active_merchant_stubs(@hd_strategy.response_code, "decline stubbed", false)
    assert_difference('Operation.count', +3) do
      assert_difference('Communication.count', +1) do
        active_member = create_active_member(@terms_of_membership)
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
    active_merchant_stubs("34234", "decline stubbed", false) 
    active_member = create_active_member(@terms_of_membership)
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
      '"05/03/2012","84.0","'+transaction.response_transaction_id+'","'+active_member.visible_id.to_s+'",""'+
      active_member.visible_id.to_s+'"","00465Z",""07/27/2012-""' +
      ',""00373475043"",""No Cardholder Authorization"","Y","4837","2206290194",""94100011003000000002""' }

    # assert_difference('Transaction', 1) do 
    #   PaymentGatewayConfiguration.process_mes_chargebacks('development')
    #   assert_equal active_member.blacklisted, true
    #   assert_equal active_member.status, "cancel"
    # end
  end


end
