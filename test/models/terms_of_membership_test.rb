require 'test_helper'

class TermsOfMembershipTest < ActiveSupport::TestCase
  setup do
    @current_agent        = FactoryBot.create(:agent)
    @club                 = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @credit_card          = FactoryBot.build(:credit_card_visa_payeezy)
  end

  test 'Should not allow to save toms with same name within same club' do
    @new_terms_of_membership = FactoryBot.build(:terms_of_membership_with_gateway, club_id: @club.id, name: @terms_of_membership.name)
    assert_not @new_terms_of_membership.save
    assert @new_terms_of_membership.errors[:name].include? 'has already been taken'
  end

  test 'Should allow to save toms with same name in different clubs' do
    @new_club = FactoryBot.create(:simple_club_with_gateway)
    @new_terms_of_membership = FactoryBot.build(:terms_of_membership_with_gateway, club_id: @new_club.id, name: @terms_of_membership.name)
    assert @new_terms_of_membership.save
  end

  test 'Should delete email templates related when deleting Tom' do
    id = @terms_of_membership.id
    @terms_of_membership.destroy
    assert_equal EmailTemplate.where(terms_of_membership_id: id).count, 0
  end

  test 'Should not allow negative amounts of club cash' do
    assert @terms_of_membership.valid?
    @terms_of_membership.initial_club_cash_amount = -10
    assert_not @terms_of_membership.valid?
    assert @terms_of_membership.errors[:initial_club_cash_amount].include? 'must be greater than or equal to 0'

    @terms_of_membership.initial_club_cash_amount = 10
    @terms_of_membership.club_cash_installment_amount = -10
    assert_not @terms_of_membership.valid?
    assert @terms_of_membership.errors[:club_cash_installment_amount].include? 'must be greater than or equal to 0'
  end

  test 'Should not allow enter invalid characters on amounts of club cash' do
    assert @terms_of_membership.valid?
    @terms_of_membership.initial_club_cash_amount = '##@@@@@&&***hjkmmmdd'
    assert_not @terms_of_membership.valid?
    assert @terms_of_membership.errors[:initial_club_cash_amount].include? 'is not a number'

    @terms_of_membership.initial_club_cash_amount = 10
    @terms_of_membership.club_cash_installment_amount = '##@@@@@&&***hjkmmmdd'
    assert_not @terms_of_membership.valid?
    assert @terms_of_membership.errors[:club_cash_installment_amount].include? 'is not a number'
  end

  test 'Should not allow enter float amounts of club cash' do
    assert @terms_of_membership.valid?
    @terms_of_membership.initial_club_cash_amount = '3,258'
    assert_not @terms_of_membership.valid?
    assert @terms_of_membership.errors[:initial_club_cash_amount].include? 'is not a number'

    @terms_of_membership.initial_club_cash_amount = 10
    @terms_of_membership.club_cash_installment_amount = '63,589'
    assert_not @terms_of_membership.valid?
    assert @terms_of_membership.errors[:club_cash_installment_amount].include? 'is not a number'
  end

  test 'Should only allow updating TOMs when there are only testing accounts or no members at all' do
    active_merchant_stubs_payeezy
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)

    @terms_of_membership.name = 'NewNameToTest'
    assert_not @terms_of_membership.save
    assert @terms_of_membership.errors[:base].include? 'There are users enrolled related to this Subscription Plan'

    user.update_attribute :testing_account, true
    assert @terms_of_membership.save
    FactoryBot.create(:prospect, terms_of_membership_id: @terms_of_membership.id)
    @terms_of_membership.name = 'NewNameToTest2'
    assert @terms_of_membership.save
  end

  test 'Should not allow deleting TOMs when there are members related to it' do
    active_merchant_stubs_payeezy
    enroll_user(FactoryBot.build(:user), @terms_of_membership)

    assert_not @terms_of_membership.destroy
    assert @terms_of_membership.errors[:base].include? 'There are users enrolled related to this Subscription Plan'
    User.delete_all
    Membership.delete_all

    prospect = FactoryBot.create(:prospect, terms_of_membership_id: @terms_of_membership.id)
    assert_not @terms_of_membership.destroy
    assert @terms_of_membership.errors[:base].include? 'There are users enrolled related to this Subscription Plan'
    prospect.delete

    assert @terms_of_membership.destroy
  end
end
