require 'test_helper'
require 'sac_mandrill/mandrill'

class SacMandrill::MemberModelTest < ActiveSupport::TestCase
  def setup
    SacMailchimp.enable_integration!
    SacMandrill.enable_integration!
    stub_mailchimp
    @club                 = FactoryBot.create(:club_with_mkt_client_mailchimp)
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @email_template       = FactoryBot.create(:mailchimp_mandrill_refund_template, terms_of_membership_id: @terms_of_membership.id)
    active_merchant_stubs_payeezy
    @user = enroll_user(FactoryBot.build(:user), @terms_of_membership, 0, true)
  end

  def stub_send_template
    Mandrill::Messages.any_instance.stubs(:send_template).returns([{ 'email' => 'example@xagax.com', 'status' => 'sent', '_id' => '12ed0a7d50ab43c793c7bd99ea03e6b6', 'reject_reason' => nil }])
  end

  def stub_send_template_with_error
    Mandrill::Messages.any_instance.stubs(:send_template).raises(Mandrill::UnknownTemplateError.new('No such template "refund2102901"'))
  end

  test 'Send notification with success' do
    stub_send_template
    Communication.deliver!(@email_template, @user)
    communication = @user.communications.find_by(template_type: @email_template.template_type)

    assert_not_nil communication
    assert communication.sent_success
    assert_equal communication.processed_at.to_date, Time.current.to_date
    assert_not_nil communication.response
  end

  test 'Send notification with error' do
    stub_send_template_with_error
    Communication.deliver!(@email_template, @user)
    communication = @user.communications.find_by(template_type: @email_template.template_type)

    assert_not_nil communication
    assert !communication.sent_success
    assert_equal communication.processed_at.to_date, Time.current.to_date
    assert_not_nil communication.response
  end
end
