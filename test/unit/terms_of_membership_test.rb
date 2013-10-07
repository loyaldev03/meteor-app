# encoding: utf-8
require 'test_helper'

class TermsOfMembershipTest < ActiveSupport::TestCase

  setup do
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
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

end