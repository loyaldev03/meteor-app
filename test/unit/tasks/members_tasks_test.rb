require 'test_helper'

class MembersTasksTest < ActiveSupport::TestCase
  setup do
    FactoryBot.create(:batch_agent)
    @club                 = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @user                 = FactoryBot.build(:user)
    active_merchant_stubs_payeezy
  end

  test 'Bill all members whose bill date is today' do
    user  = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    user2 = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    user3 = enroll_user(FactoryBot.build(:user), @terms_of_membership)

    user3.update_attribute :next_retry_bill_date, user3.next_retry_bill_date + 10.days

    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Transaction.count', 2) { TasksHelpers.bill_all_members_up_today }
      assert_not_nil user.reload.transactions.find_by(transaction_type: 'sale', operation_type: Settings.operation_types.membership_billing)
      assert_not_nil user2.reload.transactions.find_by(transaction_type: 'sale', operation_type: Settings.operation_types.membership_billing)
      assert_nil user3.reload.transactions.find_by(transaction_type: 'sale', operation_type: Settings.operation_types.membership_billing)
    end
  end

  test 'Bill members only where change_tom_date is configured in the future' do
    terms_of_membership2  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    user                  = enroll_user(FactoryBot.build(:user), @terms_of_membership)

    user.save_the_sale(terms_of_membership2.id, nil, user.next_retry_bill_date)
    assert_not_nil user.change_tom_date
    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Transaction.count', 0) { TasksHelpers.bill_all_members_up_today }
      assert_nil user.reload.transactions.find_by(transaction_type: 'sale', operation_type: Settings.operation_types.membership_billing)
    end

    user.save_the_sale(terms_of_membership2.id, nil, user.next_retry_bill_date + 1.day)
    assert_not_nil user.change_tom_date
    Timecop.travel(user.next_retry_bill_date) do
      assert_difference('Transaction.count') { TasksHelpers.bill_all_members_up_today }
      assert_not_nil user.reload.transactions.find_by(transaction_type: 'sale', operation_type: Settings.operation_types.membership_billing)
    end
  end

  test 'Scheduled save the sale (do not remove club cash)' do
    agent                 = FactoryBot.create(:confirmed_admin_agent)
    terms_of_membership2  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    user                  = enroll_user(@user, @terms_of_membership)
    user.add_club_cash agent, 100, 'testing'
    original_club_cash  = user.club_cash_amount
    scheduled_date      = (Time.current.to_date + 2.days).to_date

    assert_difference('Membership.count', 0) do
      user.save_the_sale(terms_of_membership2.id, agent, scheduled_date, remove_club_cash: false)
    end
    assert_equal user.change_tom_date, scheduled_date
    assert_equal user.change_tom_attributes, 'remove_club_cash' => false, 'terms_of_membership_id' => terms_of_membership2.id, agent_id: agent.id
    Timecop.travel(user.change_tom_date) do
      assert_difference('Membership.count', 1) do
        TasksHelpers.process_scheduled_membership_changes
      end
      user.reload
      assert_equal user.club_cash_amount, original_club_cash
      assert_nil user.change_tom_date
      assert_nil user.change_tom_attributes
      assert_equal user.current_membership.created_by_id, agent.id
      assert_equal user.terms_of_membership_id, terms_of_membership2.id
    end
  end

  test 'Scheduled save the sale (remove club cash)' do
    agent                 = FactoryBot.create(:confirmed_admin_agent)
    terms_of_membership2  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    user                  = enroll_user(@user, @terms_of_membership)
    user.add_club_cash agent, 100, 'testing'
    original_club_cash  = user.club_cash_amount
    scheduled_date      = (Time.current.to_date + 2.days).to_date

    assert_difference('Membership.count', 0) do
      user.save_the_sale(terms_of_membership2.id, agent, scheduled_date, remove_club_cash: true)
    end
    assert_equal user.change_tom_date, scheduled_date
    assert_equal user.change_tom_attributes, 'remove_club_cash' => true, 'terms_of_membership_id' => terms_of_membership2.id, :agent_id => agent.id
    assert_equal user.club_cash_amount, original_club_cash
    Timecop.travel(user.change_tom_date) do
      assert_difference('Membership.count', 1) do
        TasksHelpers.process_scheduled_membership_changes
      end
      user.reload
      assert_equal user.club_cash_amount, 0
      assert_nil user.change_tom_date
      assert_nil user.change_tom_attributes
      assert_equal user.terms_of_membership_id, terms_of_membership2.id
      assert_equal user.current_membership.created_by_id, agent.id
    end
  end

  test 'Cancellation task should cancel users' do
    saved_user  = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    saved_user2 = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    saved_user.cancel!(Time.current + 10.days, 'testing')
    saved_user2.cancel!(Time.current + 15.days, 'testing')

    Timecop.travel(saved_user.cancel_date) do
      TasksHelpers.cancel_all_member_up_today
      assert saved_user.reload.lapsed?
      assert saved_user2.reload.provisional?
    end
  end

  test 'Cancellation task should not cancel users within clubs with unset billing_enable' do
    saved_user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    saved_user.cancel!(Time.current + 10.days, 'testing')
    saved_user.club.update_attribute :billing_enable, false

    Timecop.travel(saved_user.cancel_date) do
      TasksHelpers.cancel_all_member_up_today
      assert saved_user.reload.provisional?
    end
  end

  test 'Cancellation task should cancel users with future save_the_sale scheduled' do
    terms_of_membership2  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    saved_user            = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    saved_user.save_the_sale(terms_of_membership2.id, nil, saved_user.next_retry_bill_date)

    saved_user.cancel!(saved_user.next_retry_bill_date - 1.day, 'testing')

    Timecop.travel(saved_user.cancel_date) do
      TasksHelpers.cancel_all_member_up_today
      assert saved_user.reload.lapsed?
    end
  end

  test 'Cancelation task includes users marked as manual payment where billing date is overdued' do
    saved_user = enroll_user(@user, @terms_of_membership)
    saved_user.update_attribute :manual_payment, true
    Timecop.travel(saved_user.next_retry_bill_date + 1.day) do
      assert_difference('Operation.count', 4) do
        excecute_like_server(@club.time_zone) do
          TasksHelpers.cancel_all_member_up_today
        end
      end
      saved_user.reload
      assert_equal saved_user.status, 'lapsed'
      assert_nil saved_user.next_retry_bill_date
      assert saved_user.cancel_date.utc > saved_user.join_date.utc, "#{saved_user.cancel_date.utc} Not > #{saved_user.join_date.utc}"
      assert saved_user.operations.find_by(operation_type: Settings.operation_types.bill_overdue_cancel)
    end
  end

  test 'Send Prebill task sends email 7 and 30 days before NBD' do
    user = enroll_user(@user, @terms_of_membership)
    count = 0
    [7, 30].each do |days|
      email_template = @terms_of_membership.email_templates.where(template_type: 'prebill').first
      email_template.update_attribute :days, days
      email_template.save
      excecute_like_server(@club.time_zone) do
        Timecop.travel(user.next_retry_bill_date - days.days) do
          assert_difference('Operation.count') do
            assert_difference('Communication.count') do
              TasksHelpers.send_prebill
            end
          end
        end
      end
      user.reload
      assert_equal user.communications.where(template_name: 'Test prebill').count, count += 1
    end
  end

  test 'Send Prebill task does not send email when installment_amount is 0' do
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, installment_amount: 0)
    user                  = enroll_user(@user, @terms_of_membership)
    email_template        = @terms_of_membership.email_templates.where(template_type: 'prebill').first
    assert_not_nil email_template

    excecute_like_server(@club.time_zone) do
      Timecop.travel(user.next_retry_bill_date - email_template.days) do
        assert_difference('Operation.count', 0) do
          assert_difference('Communication.count', 0) do
            TasksHelpers.send_prebill
          end
        end
      end
    end
  end

  test 'Send Prebill task does not send email when recycled_times is not 0' do
    user = enroll_user(@user, @terms_of_membership)
    user.update_attribute :recycled_times, 1
    email_template = @terms_of_membership.email_templates.where(template_type: 'prebill').first
    assert_not_nil email_template

    excecute_like_server(@club.time_zone) do
      Timecop.travel(user.next_retry_bill_date - email_template.days) do
        assert_difference('Operation.count', 0) do
          assert_difference('Communication.count', 0) do
            TasksHelpers.send_prebill
          end
        end
      end
    end
  end

  test 'Send pillar emails with same marketing client as configured in club' do
    user                                  = enroll_user(@user, @terms_of_membership)
    email_template                        = FactoryBot.create(:email_template_for_action_mailer, terms_of_membership_id: @terms_of_membership.id)
    email_template_for_mailchimp_mandrill = FactoryBot.create(:email_template_for_mailchimp_mandrill, terms_of_membership_id: @terms_of_membership.id)
    user.club.update_attribute :marketing_tool_client, 'action_mailer'

    assert_equal email_template.days, email_template_for_mailchimp_mandrill.days

    excecute_like_server(@club.time_zone) do
      Timecop.travel(user.join_date + email_template.days.days) do
        assert_difference('Communication.count') do
          TasksHelpers.send_pillar_emails
          user.reload
          assert_not_nil user.communications.find_by(template_type: 'pillar', client: 'action_mailer')
          assert_nil user.communications.find_by(template_type: 'pillar', client: 'mailchimp_mandrill')
        end
      end
    end
  end

  test 'Send pillar emails with marketing client selected' do
    user                                  = enroll_user(@user, @terms_of_membership)
    email_template_for_exact_target       = FactoryBot.create(:email_template_for_exact_target, terms_of_membership_id: @terms_of_membership.id)
    email_template_for_mailchimp_mandrill = FactoryBot.create(:email_template_for_mailchimp_mandrill, terms_of_membership_id: @terms_of_membership.id)

    # configure exact target
    user.club.update_attributes marketing_tool_client: 'exact_target', marketing_tool_attributes: { 'et_business_unit' => '12345', 'et_prospect_list' => '1235', 'et_members_list' => '12345', 'et_username' => '12345', 'et_password' => '12345' }
    excecute_like_server(@club.time_zone) do
      Timecop.travel(user.join_date + email_template_for_exact_target.days.days) do
        assert_difference('Communication.count', 1) do
          TasksHelpers.send_pillar_emails
        end
      end
    end
    user.reload
    communication = user.communications.where("client = 'exact_target'").first
    assert_equal 'pillar', communication.template_type

    # configure mandrill
    user.club.update_attributes marketing_tool_client: 'mailchimp_mandrill', marketing_tool_attributes: { 'mailchimp_api_key' => '12345', 'mailchimp_list_id' => '1235', 'mandrill_api_key' => '12345' }
    excecute_like_server(@club.time_zone) do
      Timecop.travel(user.join_date + email_template_for_mailchimp_mandrill.days.days) do
        assert_difference('Communication.count', 1) do
          TasksHelpers.send_pillar_emails
        end
      end
    end
    user.reload
    communication = user.communications.where("client = 'mailchimp_mandrill'").first
    assert_equal 'pillar', communication.template_type
  end

  test 'Resets club cash from users' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    assert_not_nil user.club_cash_expire_date

    Timecop.travel(user.club_cash_expire_date) do
      assert_difference('ClubCashTransaction.count') { TasksHelpers.reset_club_cash_up_today }
      assert_equal user.reload.club_cash_amount, 0.0
      assert_equal user.reload.club_cash_expire_date.to_date, (Time.current + 12.month).to_date
    end
  end

  test 'Do not resets club cash from users when club_cash_enable is unset' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    user.club.update_attribute :club_cash_enable, false
    assert_not_nil user.club_cash_expire_date

    Timecop.travel(user.club_cash_expire_date) do
      assert_difference('ClubCashTransaction.count', 0) { TasksHelpers.reset_club_cash_up_today }
      assert_not_equal user.reload.club_cash_amount, 0.0
    end
  end

  test 'Do not resets club cash from users when billing_enable is unset' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    user.club.update_attribute :billing_enable, false
    assert_not_nil user.club_cash_expire_date

    Timecop.travel(user.club_cash_expire_date) do
      assert_difference('ClubCashTransaction.count', 0) { TasksHelpers.reset_club_cash_up_today }
      assert_not_equal user.reload.club_cash_amount, 0.0
    end
  end

  test 'Unblack list marked users during the night' do
    user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    user.blacklist(Agent.first, 'testing')
    assert user.blacklisted?

    user.unblacklist(Agent.first, 'testing', 'temporary')
    assert_not user.blacklisted?
    assert_not_nil user.operations.find_by(operation_type: Settings.operation_types.unblacklisted_temporary)

    TasksHelpers.blacklist_users_unblacklisted_temporary
    assert user.reload.blacklisted?
  end

  test 'Delete testing account that are marked as such' do
    club = FactoryBot.create(:simple_club_with_gateway)
    FactoryBot.create(:user, club_id: club.id, testing_account: true)
    assert_difference('User.count', -1) do
      TasksHelpers.delete_testing_accounts
    end
  end
end
