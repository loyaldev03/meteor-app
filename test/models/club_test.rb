require 'test_helper'

class ClubTest < ActiveSupport::TestCase
  setup do
    @club = FactoryBot.build(:club)
  end

  test 'Save club with all basic data' do
    assert_difference('Club.count', 1) { assert @club.save }
  end

  test 'Should not save without name' do
    @club.name = nil
    assert !@club.save, 'Club was saved without a name'
  end

  test 'Should not save without partner_id' do
    @club.partner_id = nil
    assert !@club.save, 'Club was saved without a partner_id'
  end

  test 'Should not save without cs_phone_number' do
    @club.cs_phone_number = nil
    assert !@club.save
    assert @club.errors[:cs_phone_number].include? "can't be blank"
  end

  test 'Should not save without cs_email' do
    @club.cs_email = nil
    assert !@club.save
    assert @club.errors[:cs_email].include? "can't be blank"
  end

  test 'Should not save club with same name as already one created' do
    @club.save
    @second_club = FactoryBot.build(:club, name: @club.name)
    assert !@second_club.save
    assert @second_club.errors[:name].include? 'has already been taken'
  end

  test 'Should not save club with invalid payment_gateway_errors_email' do
    @club.payment_gateway_errors_email = 'testing,testing@example.com'
    assert !@club.save
    assert @club.errors[:payment_gateway_errors_email].include? "Invalid information. 'testing' is an invalid email."
  end

  test 'Should not save club with invalid cs_email' do
    @club.cs_email = 'testing'
    assert !@club.save
    assert @club.errors[:cs_email].include? 'is invalid'
  end

  test 'Should not allow save club with fulfillment_tracking_prefix longer than 1 character' do
    @club.fulfillment_tracking_prefix = 'AB'
    assert !@club.save
    assert @club.errors[:fulfillment_tracking_prefix].include? 'is too long (maximum is 1 character)'
  end

  test 'After creating a club, it should add ten disposition types to that club' do
    assert_difference('Enumeration.count', 17) do # 4 are Member's group type and 13 from disposition types.
      @club.save
    end
  end

  test 'Update Marketing client in a club with more users than the treshold configured to sync with marketing client' do
    @club.members_count = Settings.maximum_number_of_subscribers_to_automatically_resync + 1
    @club.save

    Delayed::Worker.delay_jobs = true
    assert_difference('DelayedJob.count', 0) do
      @club.description = 'new description'
      @club.save
    end
    assert_difference('DelayedJob.count', 1) do
      @club.marketing_tool_client = 'exact_target'
      @club.save
    end
    assert_difference('DelayedJob.count', 0) do
      @club.marketing_tool_client = ''
      @club.save
    end
    assert_difference('DelayedJob.count', 0) do
      @club.marketing_tool_client = 'action_mailer'
      @club.save
    end
    assert_difference('DelayedJob.count', 1) do
      @club.marketing_tool_client = 'mailchimp_mandrill'
      @club.save
    end
    Delayed::Worker.delay_jobs = false
  end

  test 'Do not allow to configurate two clubs with the same Mailchimp list' do
    @mailchimp_club                 = FactoryBot.create(:club, marketing_tool_client: 'mailchimp_mandrill', marketing_tool_attributes: { 'mailchimp_list_id' => '12345' })
    @club.marketing_tool_client     = 'mailchimp_mandrill'
    @club.marketing_tool_attributes = { 'mailchimp_list_id' => '12345' }
    assert !@club.save
    assert @club.errors.messages[:marketing_tool_attributes].include? 'mailchimp_list_id;List ID 12345 is already configured in another club.'
  end

  test 'Sanitize urls before validation' do
    %i[member_banner_url non_member_banner_url member_landing_url non_member_landing_url].each do |field|
      @club.try("#{field}=", 'testing.com')
      @club.valid?
      assert_equal @club.try(field), 'http://testing.com'
    end
  end
end
