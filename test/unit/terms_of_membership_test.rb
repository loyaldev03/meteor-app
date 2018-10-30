# encoding: utf-8
require 'test_helper'

class TermsOfMembershipTest < ActiveSupport::TestCase

  setup do
    @current_agent = FactoryBot.create(:agent)
    @club = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @user = FactoryBot.build(:user)
    @credit_card = FactoryBot.build(:credit_card_visa_payeezy)
  end

  def enroll_user(tom, amount=23, cc_blank=false, cc_card = nil)
    active_merchant_stubs_payeezy("100", "Transaction Normal - Approved with Stub", true, @credit_card.number)
    credit_card = cc_card.nil? ? @credit_card : cc_card
    answer = User.enroll(tom, @current_agent, amount, 
      { first_name: @user.first_name,
        last_name: @user.last_name, address: @user.address, city: @user.city, gender: 'M',
        zip: @user.zip, state: @user.state, email: @user.email, type_of_phone_number: @user.type_of_phone_number,
        phone_country_code: @user.phone_country_code, phone_area_code: @user.phone_area_code,
        phone_local_number: @user.phone_local_number, country: 'US', 
        product_sku: Settings.others_product }, 
      { number: credit_card.number, 
        expire_year: credit_card.expire_year, expire_month: credit_card.expire_month },
      cc_blank)

    assert (answer[:code] == Settings.error_codes.success), answer[:message]+answer.inspect

    user = User.find(answer[:member_id])
    assert_not_nil user
    assert_equal user.status, 'provisional'
    user
  end

  test "Should not allow to save toms with same name within same club" do
  	@new_terms_of_membership = FactoryBot.build(:terms_of_membership_with_gateway, :club_id => @club.id, :name => @terms_of_membership.name)
  	assert !@new_terms_of_membership.save
  end

  test "Should allow to save toms with same name in different clubs" do
  	@new_club = FactoryBot.create(:simple_club_with_gateway)
  	@new_terms_of_membership = FactoryBot.build(:terms_of_membership_with_gateway, :club_id => @new_club.id, :name => @terms_of_membership.name)
  	assert @new_terms_of_membership.save
  end

  test "Should delete email teplates related when deleting Tom" do
  	id = @terms_of_membership.id
  	@terms_of_membership.destroy
  	assert_equal EmailTemplate.where(:terms_of_membership_id => id).count, 0
  end

  test "Should not allow negative amounts of club cash" do
  	assert @terms_of_membership.valid?
  	@terms_of_membership.initial_club_cash_amount = -10
  	assert !@terms_of_membership.valid?
  	@terms_of_membership.initial_club_cash_amount = 10
  	@terms_of_membership.club_cash_installment_amount = -10
  	assert !@terms_of_membership.valid?
  end

  # Create a TOM with upgrate to >1
  test "Create an user with TOM upgrate to >1" do
    active_merchant_stubs_payeezy
    @terms_of_membership_with_upgrade = FactoryBot.create(:terms_of_membership_with_gateway, 
                                                           :club_id => @club.id, :upgrade_tom_id => @terms_of_membership.id, 
                                                           :upgrade_tom_period => 65, :provisional_days => 30, :installment_period => 30 )

    user = enroll_user(@terms_of_membership_with_upgrade)
    nbd = user.next_retry_bill_date
    next_month = Time.zone.now.to_date + user.terms_of_membership.installment_period.days
    #first billing, it should not upgrade 
    Timecop.travel(user.next_retry_bill_date) do
      assert_difference("Operation.count", 4) do
        TasksHelpers.bill_all_members_up_today
      end      
      user.reload
      assert_equal user.current_membership.terms_of_membership_id, @terms_of_membership_with_upgrade.id
    end
    #Second billing, it should not upgrade 
    Timecop.travel(user.next_retry_bill_date) do
      assert_difference("Operation.count", 5) do
        TasksHelpers.bill_all_members_up_today
      end
      user.reload
      assert_equal user.current_membership.terms_of_membership_id, @terms_of_membership_with_upgrade.id
    end
    #Third billing, it should upgrade 
    Timecop.travel(user.next_retry_bill_date) do
      assert_difference("Operation.count", 7) do
        TasksHelpers.bill_all_members_up_today
      end
      user.reload
      assert_equal user.current_membership.terms_of_membership_id, @terms_of_membership.id
      assert_not_nil user.operations.where(operation_type: Settings.operation_types.tom_upgrade).first
    end
  end

  #Create a TOM with upgrate to = 1
  test "Create an user with TOM upgrate to = 1" do
    active_merchant_stubs_payeezy
    @terms_of_membership_with_upgrade = FactoryBot.build(:terms_of_membership_with_gateway, 
                                                           :club_id => @club.id, :upgrade_tom_id => @terms_of_membership.id, 
                                                           :upgrade_tom_period => 1, :provisional_days => 30, :installment_period => 30 )
    assert @terms_of_membership_with_upgrade.save
    user = enroll_user(@terms_of_membership_with_upgrade)
  end

  test "Create an user with Manual Payment with TOM upgrate to >1" do
    active_merchant_stubs_payeezy
    @terms_of_membership_with_upgrade = FactoryBot.create(:terms_of_membership_with_gateway, 
                                                           :club_id => @club.id, :upgrade_tom_id => @terms_of_membership.id, 
                                                           :upgrade_tom_period => 65, :provisional_days => 30, :installment_period => 30 )

    user = enroll_user(@terms_of_membership_with_upgrade)
    user.update_attribute :manual_payment, true

    #first billing, it should not upgrade  
    Timecop.travel(user.next_retry_bill_date) do
      assert_difference("Operation.count", 3) do
        user.manual_billing(@terms_of_membership_with_upgrade.installment_amount, 'cash')
      end      
      user.reload
      assert_equal user.current_membership.terms_of_membership_id, @terms_of_membership_with_upgrade.id
    end
    #Second billing, it should not upgrade 
    Timecop.travel(user.next_retry_bill_date) do
      assert_difference("Operation.count", 3) do
        user.manual_billing(@terms_of_membership_with_upgrade.installment_amount, 'cash')
      end
      user.reload
      assert_equal user.current_membership.terms_of_membership_id, @terms_of_membership_with_upgrade.id
    end
    #Third billing, it should upgrade 
    Timecop.travel(user.next_retry_bill_date) do
      assert_difference("Operation.count", 5) do
        user.manual_billing(@terms_of_membership_with_upgrade.installment_amount, 'cash')
      end
      user.reload
      assert_equal user.current_membership.terms_of_membership_id, @terms_of_membership.id
      assert_not_nil user.operations.where(operation_type: Settings.operation_types.tom_upgrade).first
    end
  end

  test "Should only allow updating TOMs when there are only testing accounts or no members at all" do
    active_merchant_stubs_payeezy
    user = enroll_user(@terms_of_membership)

    @terms_of_membership.name = "NewNameToTest"    
    assert !@terms_of_membership.save
    user.update_attribute :testing_account, true
    assert @terms_of_membership.save
    FactoryBot.create(:prospect, terms_of_membership_id: @terms_of_membership.id)
    @terms_of_membership.name = "NewNameToTest2"
    assert @terms_of_membership.save
  end

  test "Should not allow deleting TOMs when there are members related to it" do
    active_merchant_stubs_payeezy
    user = enroll_user(@terms_of_membership)
    
    assert !@terms_of_membership.destroy
    User.delete_all
    Membership.delete_all
    prospect = FactoryBot.create(:prospect, terms_of_membership_id: @terms_of_membership.id)
    assert !@terms_of_membership.destroy
    prospect.delete
    assert @terms_of_membership.destroy
  end
end