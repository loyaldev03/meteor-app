require 'test_helper'

class EmailTemplateTest < ActiveSupport::TestCase
  def setup
    @club                 = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
  end

  test 'Should not save email template without name' do
    email_template = FactoryBot.build(:email_template, terms_of_membership_id: @terms_of_membership.id,
                                                       name: '')
    assert !email_template.save
    assert email_template.errors[:name].include? "can't be blank"
  end

  test 'Should not save email template without terms_of_membership' do
    email_template = FactoryBot.build(:email_template)
    assert !email_template.save
    assert email_template.errors[:terms_of_membership_id].include? "can't be blank"
  end

  test 'Should not save email template without template_type' do
    email_template = FactoryBot.build(:email_template, terms_of_membership_id: @terms_of_membership.id,
                                                       template_type: '')
    assert !email_template.save
    assert email_template.errors[:template_type].include? "can't be blank"
  end

  test 'Should not save email template without client' do
    email_template = FactoryBot.build(:email_template, terms_of_membership_id: @terms_of_membership.id,
                                                       client: '')
    assert !email_template.save
    assert email_template.errors[:client].include? "can't be blank"
  end

  test 'Should not allow email templates with duplicated name, client and terms_of_membership_id' do
    email_template      = FactoryBot.create(:email_template, terms_of_membership_id: @terms_of_membership.id)
    dup_email_template  = FactoryBot.build(:email_template_for_action_mailer, terms_of_membership_id: @terms_of_membership.id)

    dup_email_template.name = email_template.name
    assert dup_email_template.valid?

    dup_email_template.client = email_template.client
    assert !dup_email_template.save
    assert dup_email_template.errors[:name].include? 'has already been taken'
  end

  test 'Should not save pillar email template without days' do
    email_template = FactoryBot.build(:email_template, terms_of_membership_id: @terms_of_membership.id,
                                                       template_type: 'pillar', days: nil)
    assert !email_template.save
    assert email_template.errors[:days].include? 'is not a number'
    email_template.days = 0
    assert !email_template.save
    assert email_template.errors[:days].include? 'must be greater than or equal to 1'
    email_template.days = 1001
    assert !email_template.save
    assert email_template.errors[:days].include? 'must be less than or equal to 1000'
  end
end
