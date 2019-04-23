require 'test_helper'

class SaveTheSaleTest < ActionDispatch::IntegrationTest
  setup do
    @admin_agent                          = FactoryBot.create(:confirmed_admin_agent)
    @partner                              = FactoryBot.create(:partner)
    @club                                 = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    Time.zone                             = @club.time_zone
    @terms_of_membership_with_gateway     = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @terms_of_membership_with_gateway2    = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id, name: 'second_tom_without_aproval')
    @terms_of_membership_with_approval    = FactoryBot.create(:terms_of_membership_with_gateway_needs_approval, club_id: @club.id)
    @terms_of_membership_with_approval2   = FactoryBot.create(:terms_of_membership_with_gateway_needs_approval, club_id: @club.id, name: 'second_tom_aproval')
    @new_terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_hold_card, club_id: @club.id)
    @lifetime_terms_of_membership         = FactoryBot.create(:life_time_terms_of_membership, club_id: @club.id)
    @member_cancel_reason                 = FactoryBot.create(:member_cancel_reason)
    sign_in_as(@admin_agent)
  end

  def setup_user(approval = false, active = false)
    unsaved_user    = FactoryBot.build(:user_with_api)
    credit_card     = FactoryBot.build(:credit_card_master_card)
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    tom             = approval ? @terms_of_membership_with_approval : @terms_of_membership_with_gateway
    @saved_user     = create_user_by_sloop(@admin_agent, unsaved_user, credit_card, enrollment_info, tom)
    @saved_user.set_as_active if active
    @old_membership = @saved_user.current_membership
  end

  def save_the_sale(user, new_terms_of_membership, schedule_date = nil, remove_club_cash = false, validate = true)
    original_membership       = user.current_membership
    original_status           = user.status
    next_retry_bill_date_old  = user.next_retry_bill_date

    visit show_user_path(partner_prefix: user.club.partner.prefix, club_prefix: user.club.name, user_prefix: user.id)
    click_on 'Save the sale'
    check('show_all_toms')
    select(new_terms_of_membership.name, from: 'terms_of_membership_id')
    select_from_datepicker('change_tom_date', schedule_date) if schedule_date
    check 'remove_club_cash' if remove_club_cash
    click_on 'Save the sale'
    confirm_ok_js

    if validate
      assert page.has_content?('Save the sale succesfully applied')
      original_membership.reload
      assert_equal next_retry_bill_date_old, user.reload.next_retry_bill_date
      if schedule_date
        within('#td_mi_status') { assert page.has_content?(user.status) }
        within('#table_membership_information') { find('td', text: original_membership.terms_of_membership.name, match: :first) }
        within('.nav-tabs') { click_on 'Operations' }
        within('#operations') do
          find('tr', text: "User scheduled to be changed to TOM(#{new_terms_of_membership.id}) -#{new_terms_of_membership.name}- at #{schedule_date}.")
        end
        within('.nav-tabs') { click_on 'Memberships' }
        within('#memberships_table') do
          within('tr', text: user.current_membership.id) { find('td', text: original_status) }
        end

        click_on 'Details'
        within('#myModalFutureTomChange') do
          assert page.has_content? new_terms_of_membership.name
          assert page.has_content? schedule_date
        end
      else
        within('#td_mi_status') { assert page.has_content?(new_terms_of_membership.needs_enrollment_approval? ? 'applied' : 'provisional') }
        within('#table_membership_information') { find('td', text: new_terms_of_membership.name, match: :first) }
        within('.nav-tabs') { click_on 'Operations' }
        within('#operations') do
          find('tr', text: "Save the sale from TOM(#{original_membership.terms_of_membership.id}) to TOM(#{new_terms_of_membership.id})")
        end

        within('.nav-tabs') { click_on 'Memberships' }
        within('#memberships_table') do
          within('tr', text: user.current_membership.id) { find('td', text: new_terms_of_membership.needs_enrollment_approval? ? 'applied' : 'provisional') }
        end
      end
      within('#td_mi_next_retry_bill_date') { assert page.has_content?(I18n.l(user.next_retry_bill_date, format: :only_date)) } unless %w[applied lapsed].include? user.status
    end
  end

  test 'save the sale from provisional to provisional' do
    setup_user
    assert_equal @saved_user.status, 'provisional'
    save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
  end

  test 'save the sale from active to provisional' do
    setup_user(false, true)
    assert_equal @saved_user.status, 'active'
    save_the_sale(@saved_user, @new_terms_of_membership_with_gateway)
  end

  test 'save the sale with the same TOM' do
    setup_user(false, true)
    assert_equal @saved_user.status, 'active'
    save_the_sale(@saved_user, @saved_user.current_membership.terms_of_membership, nil, false, false)
    assert page.has_content?('Nothing to change. Member is already enrolled on that TOM')
  end

  test 'user save the sale full save' do
    setup_user
    @saved_user.bill_membership
    visit user_save_the_sale_path(partner_prefix: @partner.prefix, club_prefix: @club.name, user_prefix: @saved_user.id, transaction_id: Transaction.last.id)
    click_on 'Full save'
    assert page.has_content?('Full save done')
    within('.nav-tabs') { click_on 'Operations' }
    within('#operations_table') do
      assert page.has_content?('Full save done')
    end
  end

  test 'save the sale with remove club cash option as true' do
    setup_user
    save_the_sale(@saved_user, @new_terms_of_membership_with_gateway, nil, true)
    @saved_user.reload
    assert_equal @saved_user.club_cash_amount, 0
  end

  test 'schedule save the sale selecting club cash remove as true' do
    setup_user
    schedule_date = Time.current.to_date + 2.days
    save_the_sale(@saved_user, @new_terms_of_membership_with_gateway, schedule_date, true)
    assert_equal @saved_user.reload.change_tom_attributes, { 'remove_club_cash' => true, 'terms_of_membership_id' => @new_terms_of_membership_with_gateway.id, 'agent_id' => @admin_agent.id }
    assert @saved_user.club_cash_amount != 0
  end

  test 'schedule save the sale selecting club cash remove as false' do
    setup_user
    schedule_date = Time.current.to_date + 2.days
    save_the_sale(@saved_user, @new_terms_of_membership_with_gateway, schedule_date, false, false)
    @saved_user.reload
    assert_equal @saved_user.change_tom_date, schedule_date
    assert_equal @saved_user.change_tom_attributes, 'remove_club_cash' => false, 'terms_of_membership_id' => @new_terms_of_membership_with_gateway.id, 'agent_id' => @admin_agent.id
    assert @saved_user.club_cash_amount != 0
    within('#td_mi_future_tom_change') do
      assert page.has_content? schedule_date
      click_on 'Details'
      assert page.has_content? @new_terms_of_membership_with_gateway.name
    end
  end
end
