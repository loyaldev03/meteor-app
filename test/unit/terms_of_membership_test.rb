# encoding: utf-8
require 'test_helper'

class TermsOfMembershipTest < ActiveSupport::TestCase

  setup do
    @current_agent = FactoryGirl.create(:agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @member = FactoryGirl.build(:member)
    @credit_card = FactoryGirl.build(:credit_card)
  end

  def enroll_member(tom, amount=23, cc_blank=false, cc_card = nil)
    credit_card = cc_card.nil? ? @credit_card : cc_card
    answer = Member.enroll(tom, @current_agent, amount, 
      { first_name: @member.first_name,
        last_name: @member.last_name, address: @member.address, city: @member.city, gender: 'M',
        zip: @member.zip, state: @member.state, email: @member.email, type_of_phone_number: @member.type_of_phone_number,
        phone_country_code: @member.phone_country_code, phone_area_code: @member.phone_area_code,
        type_of_phone_number: 'Home', phone_local_number: @member.phone_local_number, country: 'US', 
        product_sku: Settings.kit_card_product }, 
      { number: credit_card.number, 
        expire_year: credit_card.expire_year, expire_month: credit_card.expire_month },
      cc_blank)

    assert (answer[:code] == Settings.error_codes.success), answer[:message]+answer.inspect

    member = Member.find(answer[:member_id])
    assert_not_nil member
    assert_equal member.status, 'provisional'
    member
  end

  test "Should not allow to save toms with same name within same club" do
  	@new_terms_of_membership = FactoryGirl.build(:terms_of_membership_with_gateway, :club_id => @club.id, :name => @terms_of_membership.name)
  	assert !@new_terms_of_membership.save
  end

  test "Should allow to save toms with same name in different clubs" do
  	@new_club = FactoryGirl.create(:simple_club_with_gateway)
  	@new_terms_of_membership = FactoryGirl.build(:terms_of_membership_with_gateway, :club_id => @new_club.id, :name => @terms_of_membership.name)
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

  # Create a member with TOM before
  test "After successful billing it should upgrade member if upgrade_tom was set" do
    active_merchant_stubs
    @terms_of_membership_with_upgrade = FactoryGirl.create(:terms_of_membership_with_gateway, 
                                                           :club_id => @club.id, :upgrade_tom_id => @terms_of_membership.id, 
                                                           :upgrade_tom_period => 65, :provisional_days => 30, :installment_period => 30 )

    member = enroll_member(@terms_of_membership_with_upgrade)
    nbd = member.next_retry_bill_date
    next_month = Time.zone.now.to_date + member.terms_of_membership.installment_period.days
    #first billing, it should not upgrade 
    Timecop.travel(member.next_retry_bill_date) do
      assert_difference("Operation.count", 3) do
        Member.bill_all_members_up_today
      end      
      member.reload
      assert_equal member.current_membership.terms_of_membership_id, @terms_of_membership_with_upgrade.id
    end
    #Second billing, it should not upgrade 
    Timecop.travel(member.next_retry_bill_date) do
      assert_difference("Operation.count", 3) do
        Member.bill_all_members_up_today
      end
      member.reload
      assert_equal member.current_membership.terms_of_membership_id, @terms_of_membership_with_upgrade.id
    end
    #Third billing, it should upgrade 
    Timecop.travel(member.next_retry_bill_date) do
      assert_difference("Operation.count", 5) do
        Member.bill_all_members_up_today
      end
      member.reload
      assert_equal member.current_membership.terms_of_membership_id, @terms_of_membership.id
      assert_not_nil member.operations.where(operation_type: Settings.operation_types.tom_upgrade).first
    end
  end

end