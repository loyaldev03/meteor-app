require 'test_helper'

class TransactionTest < ActiveSupport::TestCase
  setup do
    @current_agent = FactoryGirl.create(:agent)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway)
    @member = FactoryGirl.build(:member)
    @credit_card = FactoryGirl.build(:credit_card)
  end

  test "save operation" do
    assert_difference('Operation.count') do
      Auditory.audit(@current_agent, nil, "test")
    end
  end

  test "enrollment" do
    assert_difference('Operation.count') do
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

  test "controlled refund (refund completely a transaction)" do
    paid_member = FactoryGirl.create(:paid_member, terms_of_membership: @terms_of_membership, club: @terms_of_membership.club)
    amount = @terms_of_membership.installment_amount
    answer = paid_member.bill_membership
    assert_equal paid_member.status, 'paid'
    assert_difference('Operation.count') do
      count = Transaction.count
      trans = paid_member.transactions.last
      answer = Transaction.refund(amount, trans)
      assert (answer[:code] == Settings.error_codes.success), answer[:message]
      trans.reload
      assert_equal Transaction.count, count + 1
      assert_equal trans.refunded_amount, amount
      assert_equal trans.amount_available_to_refund, 0.0
    end
  end


  # AGREGAR TEST:
  # - member monthly bill, NBD change
  # - member yearly bill, NBD change
  # - member bill SD, NBD change , bill_date not change, recycled_times increment
  # - member bill HD, Cancellation => envio mail

end
