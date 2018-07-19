require 'test_helper'

class ClubTest < ActiveSupport::TestCase

  setup do
    @club = FactoryBot.build(:club)
  end

  test "Should not save without name" do
  	@club.name = nil
  	assert !@club.save, "Club was saved without a name"
  end

  test "Should not save without partner_id" do
  	@club.partner_id = nil
  	assert !@club.save, "Club was saved without a partner_id"
  end

  test "After creating a club, it should add ten disposition types to that club" do
    assert_difference('Enumeration.count',17) do  #4 are Member's group type and 13 from disposition types.
      @club.save
    end
  end

  test "Update Marketing client in a club with more users than the treshold configured to sync with marketing client" do
    @club.members_count = Settings.maximum_number_of_subscribers_to_automatically_resync + 1
    @club.save

    Delayed::Worker.delay_jobs = true
    assert_difference("DelayedJob.count", 0) do
      @club.description = "new description"
      @club.save
    end
    assert_difference("DelayedJob.count", 1) do
      @club.marketing_tool_client = 'exact_target'
      @club.save
    end
    assert_difference("DelayedJob.count", 0) do
      @club.marketing_tool_client = ''
      @club.save
    end
    assert_difference("DelayedJob.count", 0) do
      @club.marketing_tool_client = 'action_mailer'
      @club.save
    end
    assert_difference("DelayedJob.count", 1) do
      @club.marketing_tool_client = 'mailchimp_mandrill'
      @club.save
    end
    Delayed::Worker.delay_jobs = false
  end

  test "Do not allow to configurate two clubs with the same Mailchimp list" do
    @mailchimp_club = FactoryBot.create(:club, marketing_tool_client: 'mailchimp_mandrill', marketing_tool_attributes: {'mailchimp_list_id'=>"12345"})
    @club.marketing_tool_client = 'mailchimp_mandrill'
    @club.marketing_tool_attributes = {'mailchimp_list_id'=>"12345"}
    assert !@club.save
    assert @club.errors.messages[:marketing_tool_attributes].include? "mailchimp_list_id;List ID 12345 is already configured in another club."
  end 

end
