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

  test "Enrollment" do
    active_merchant_stubs unless @use_active_merchant
    assert_difference('Operation.count') do
      assert_difference('Fulfillment.count') do
        answer = Member.enroll(@terms_of_membership, @current_agent, 23, 
          { first_name: @member.first_name,
            last_name: @member.last_name, address: @member.address, city: @member.city,
            zip: @member.zip, state: @member.state, email: @member.email, 
            phone_number: @member.phone_number, country: 'US' }, 
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
    paid_member = FactoryGirl.create(:paid_member, terms_of_membership: @terms_of_membership, club: @terms_of_membership.club)
    amount = @terms_of_membership.installment_amount
    answer = paid_member.bill_membership
    assert_equal paid_member.status, 'paid'
    assert_difference('Operation.count', +2) do
      assert_difference('Transaction.count') do
        assert_difference('Communication.count') do
          trans = paid_member.transactions.last
          answer = Transaction.refund(amount, trans)
          assert (answer[:code] == Settings.error_codes.success), answer[:message]
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
    assert_difference('Operation.count', +1) do
      assert_difference('Transaction.count') do
        paid_member = FactoryGirl.create(:paid_member, terms_of_membership: @terms_of_membership, club: @terms_of_membership.club)
        nbd = paid_member.bill_date
        answer = paid_member.bill_membership
        assert !paid_member.lapsed?, "member cant be lapsed"
        assert_equal paid_member.next_retry_bill_date.to_date, @sd_strategy.days.days.from_now.to_date, "next_retry_bill_date should #{@sd_strategy.days.days.from_now}"
        assert_equal paid_member.bill_date, nbd, "bill_date should not be touched #{nbd}"
        assert_equal paid_member.recycled_times, 1, "recycled_times should be 1"
      end
    end
  end
  test "Billing with grace period enabled on tom and missing CC" do
    @grace_strategy = FactoryGirl.create(:grace_period_decline_strategy)
    paid_member = FactoryGirl.create(:paid_member_without_cc, terms_of_membership: @terms_of_membership, club: @terms_of_membership.club)
    nbd = paid_member.bill_date
    @terms_of_membership.grace_period = 15
    @terms_of_membership.save
    answer = paid_member.bill_membership
#TODO

  end
  test "Billing with grace period disable on tom and missing CC" do
    paid_member = FactoryGirl.create(:paid_member_without_cc, terms_of_membership: @terms_of_membership, club: @terms_of_membership.club)
    nbd = paid_member.bill_date
    @terms_of_membership.grace_period = 0
    @terms_of_membership.save
    answer = paid_member.bill_membership
#TODO

  end
  test "Billing with SD reaches the recycle limit, and HD cancels member." do 
    active_merchant_stubs(@sd_strategy.response_code, "decline stubbed", false) 
    assert_difference('Operation.count', +3) do
      paid_member = FactoryGirl.create(:paid_member, terms_of_membership: @terms_of_membership, club: @terms_of_membership.club)
      amount = @terms_of_membership.installment_amount
      paid_member.recycled_times = 4
      paid_member.save
      answer = paid_member.bill_membership
      assert (answer[:code] != Settings.error_codes.success), "#{answer[:code]} cant be 000 (success)"
      assert paid_member.lapsed?, "member should be lapsed after recycle limit is reached"
      assert_nil paid_member.next_retry_bill_date, "next_retry_bill_date should be nil"
      assert_nil paid_member.bill_date, "bill_date should be nil"
      assert_equal paid_member.recycled_times, 0, "recycled_times should be 0"
    end
  end

  test "Billing with HD cancels member" do 
    active_merchant_stubs(@hd_strategy.response_code, "decline stubbed", false)
    assert_difference('Operation.count', +2) do
      assert_difference('Communication.count', +1) do
        paid_member = FactoryGirl.create(:paid_member, terms_of_membership: @terms_of_membership, club: @terms_of_membership.club)
        amount = @terms_of_membership.installment_amount
        answer = paid_member.bill_membership
        assert paid_member.lapsed?, "member should be lapsed after HD"
        assert_nil paid_member.next_retry_bill_date, "next_retry_bill_date should be nil"
        assert_nil paid_member.bill_date, "bill_date should be nil"
        assert_equal paid_member.recycled_times, 0, "recycled_times should be 0"
      end
    end
  end

  test "Billing declined, but there is no decline rule. Send email" do 
    active_merchant_stubs("34234", "decline stubbed", false) 
    assert_difference('ActionMailer::Base.deliveries.size', 1) do 
      paid_member = FactoryGirl.create(:paid_member, terms_of_membership: @terms_of_membership, club: @terms_of_membership.club)
      amount = @terms_of_membership.installment_amount
      answer = paid_member.bill_membership
      assert_equal paid_member.next_retry_bill_date.to_date, (Date.today + eval(Settings.next_retry_on_missing_decline)).to_date, "Next retry bill date incorrect"
    end
  end
  ############################################


end
