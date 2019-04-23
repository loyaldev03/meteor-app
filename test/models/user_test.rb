# encoding: utf-8

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @club                             = FactoryBot.create(:simple_club_with_gateway)
    @partner                          = @club.partner
    Time.zone                         = @club.time_zone
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @wordpress_terms_of_membership    = FactoryBot.create :wordpress_terms_of_membership_with_gateway, club_id: @club.id
    @sd_strategy                      = FactoryBot.create(:soft_decline_strategy)
  end

  test 'Should not create an user without first name' do
    user = FactoryBot.build(:user, first_name: nil)
    assert !user.save
  end

  test 'Should not create an user without last name' do
    user = FactoryBot.build(:user, last_name: nil)
    assert !user.save
  end

  test 'Should create an user without gender' do
    user = FactoryBot.build(:user, gender: nil)
    assert !user.save
  end

  test 'Should create an user without type_of_phone_number' do
    user = FactoryBot.build(:user, type_of_phone_number: nil)
    assert !user.save
  end

  test 'Should not save with an invalid email' do
    user = FactoryBot.build(:user, email: 'testing.com.ar')
    user.valid?
    assert_not_nil user.errors, user.errors.full_messages.inspect
  end

  test 'Should not be two users with the same email within the same club' do
    user = FactoryBot.build(:user)
    user.club = @terms_of_membership_with_gateway.club
    user.save
    user_two = FactoryBot.build(:user)
    user_two.club =  @terms_of_membership_with_gateway.club
    user_two.email = user.email
    user_two.valid?
    assert_not_nil user_two, user_two.errors.full_messages.inspect
  end

  test 'Should let save two users with the same email in differents clubs' do
    @second_club = FactoryBot.create(:simple_club_with_gateway)

    user = FactoryBot.build(:user, email: 'testing@xagax.com', club: @terms_of_membership_with_gateway.club)
    user.club_id = 1
    user.save
    user_two = FactoryBot.build(:user, email: 'testing@xagax.com', club: @second_club)
    assert user_two.save, "user cant be save #{user_two.errors.inspect}"
  end

  test 'Should not let create an user with a wrong format zip' do
    ['12345-1234', '12345'].each { |zip| zip
      user = FactoryBot.build(:user, zip: zip, club: @terms_of_membership_with_gateway.club)
      assert user.save, "User cant be save #{user.errors.inspect}"
    }
    ['1234-1234', '12345-123', '1234'].each { |zip| zip
      user = FactoryBot.build(:user, zip: zip, club: @terms_of_membership_with_gateway.club)
      assert !user.save, "User cant be save #{user.errors.inspect}"
    }
  end

  test 'Should reset club_cash when user is canceled' do
    user = enroll_user(FactoryBot.build(:user), @wordpress_terms_of_membership)
    user.add_club_cash 100, 'testing'
    user.set_as_canceled
    assert_equal 0, user.reload.club_cash_amount, "The user is #{user.status} with #{user.club_cash_amount}"
  end

  test 'Should cancel fulfillment if user gets cancelled before two days.' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    fulfillment = user.fulfillments.first
    assert fulfillment.not_processed?
    user.set_as_canceled
    assert user.lapsed?
    assert user.fulfillments.first.canceled?
  end

  test 'Should NOT cancel fulfillment if user gets cancelled after two days.' do
    user        = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    fulfillment = user.fulfillments.first
    assert fulfillment.not_processed?

    Timecop.travel(Time.current + 3.days) do
      user.set_as_canceled
      assert user.lapsed?
      assert fulfillment.not_processed?
    end
  end

  test 'User should be saved with first_name and last_name with numbers or acents.' do
    user = FactoryBot.build(:user)
    assert !user.save, user.errors.inspect
    user.club = @terms_of_membership_with_gateway.club
    user.first_name = 'Billy 3ro'
    user.last_name = 'Sáenz'
    assert user.save, "user cant be save #{user.errors.inspect}"
  end

  test 'Should not deduct more club_cash than the user has' do
    user                      = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    original_club_cash_amount = user.club_cash_amount
    assert original_club_cash_amount < 299

    user.add_club_cash(-300)
    assert_equal original_club_cash_amount, user.club_cash_amount, "The user is #{user.status} with $#{user.club_cash_amount}"
  end

  test 'if active user is blacklisted, should have cancel date set' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    assert user.provisional?
    assert_nil user.cancel_date

    user.blacklist(nil, 'Test')
    assert_not_nil user.reload.cancel_date
    assert_equal user.blacklisted, true
  end

  test 'if lapsed user is blacklisted, it should not be canceled again' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
    user.cancel! Time.current, 'testing'
    user.set_as_canceled!
    assert user.lapsed?

    cancel_date = user.cancel_date
    Timecop.travel(Time.current + 10.days) do
      assert_difference('Operation.count', 1) { user.blacklist(nil, 'Test') }
      assert_not_nil user.reload.cancel_date
      assert_equal user.cancel_date.to_date, cancel_date.to_date
      assert_equal user.blacklisted, true
    end
  end

  test 'Add club cash - more than maximum value on an user related to drupal' do
    agent   = FactoryBot.create(:confirmed_admin_agent)
    club    = FactoryBot.create(:club_with_api)
    user    = FactoryBot.create(:user_with_api, club_id: club.id)
    user.add_club_cash(agent, 12385243.2)
  end

  test 'User email validation' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership_with_gateway)
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
end
