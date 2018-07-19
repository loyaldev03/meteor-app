require 'test_helper'
 
class UsersClubCashTest < ActionDispatch::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  def setup_user(create_user = true)
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    @partner = FactoryBot.create(:partner)
    @club = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    
    if create_user
      @saved_user = create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent })
    end
    sign_in_as(@admin_agent)
  end

  def create_user_throught_sloop(enrollment_info, terms_of_membership)
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    Time.zone = @club.time_zone

    @credit_card = FactoryBot.build :credit_card
    @user = FactoryBot.build :active_user
    create_user_by_sloop(@admin_agent, @user, @credit_card, enrollment_info, terms_of_membership)
    sign_in_as(@admin_agent)
  end

  ###########################################################
  # TESTS
  ###########################################################

  # Remove/Add Club Cash
  # See club cash transaction history (Only Clubs without Drupal domain)
  test "Message after Club Cash addition" do
    setup_user

    visit show_user_path(:partner_prefix => @saved_user.club.partner.prefix, :club_prefix => @saved_user.club.name, :user_prefix => @saved_user.id)
    within("#table_membership_information"){ click_on 'Add club cash' }
    find( "tr", :text => I18n.t('activerecord.attributes.club_cash_transaction.amount_help') )

    fill_in 'club_cash_transaction[amount]', :with => 5
    fill_in 'club_cash_transaction[description]', :with => "description"
    click_on 'Save club cash transaction'
    sleep 1
    page.driver.browser.switch_to.alert.accept 
  end

  test "add club cash amount" do
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    add_club_cash(@saved_user, 15, "Generic description")
    @saved_user.reload
    add_club_cash(@saved_user, -5, "Generic description")
  end

  test "club cash amount can't be negatibe" do
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    add_club_cash(@saved_user, 15, "Generic description")
    add_club_cash(@saved_user, -20, "Deducting more than user has.", false)
    @saved_user.reload
    assert page.has_content?("You can not deduct 20.0 because the user only has 15.0 club cash.")
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#td_mi_club_cash_amount") { assert page.has_content?("15") }
  end

  # Error message when adding a wrong club cash
  test "invalid characters on club cash" do
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    click_on 'Add club cash'
    fill_in 'club_cash_transaction[amount]', :with => "random text"
    alert_ok_js
    assert_difference('ClubCashTransaction.count', 0) do
      click_on 'Save club cash transaction'
    end
    
    fill_in 'club_cash_transaction[amount]', :with => "0"
    alert_ok_js
    click_on 'Save club cash transaction'
    assert page.has_content?('Can not process club cash transaction with amount 0 or letters.')    
  end

  test "add club cash with float ammount" do
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    click_on 'Add club cash'
    fill_in 'club_cash_transaction[amount]', :with => "0.99"
    alert_ok_js
    click_on 'Save club cash transaction'
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#td_mi_club_cash_amount") { assert page.has_content?("0.99") }
    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table")do
      assert page.has_content?('0.99 club cash was successfully added.')
    end
  end

  test "create user with terms_of_membership without club cash" do
    setup_user false
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway_without_club_cash, :club_id => @club.id)
    @saved_user = create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent })
    @saved_user.bill_membership
    sleep(1) #To wait until billing is finished.
    @saved_user.reload
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within(".nav-tabs"){ click_on("Operations") }
    within("#operations_table")do
      assert page.has_no_content?('0 club cash was successfully added.')
    end
  end

  test "user cancelation must set to 0 the club cash" do
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    click_on 'Add club cash'
    fill_in 'club_cash_transaction[amount]', :with => "99"
    alert_ok_js
    click_on 'Save club cash transaction'
    within("#table_membership_information"){
      within("#td_mi_club_cash_amount"){
          assert page.has_content?('99.0')
      }
    }

    @saved_user.set_as_canceled
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_membership_information"){
      within("#td_mi_club_cash_amount"){
          assert page.has_content?('0')
      }
    }
  end 

  test "user cancelation must set club cash expired day as nil" do
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    click_on 'Add club cash'
    fill_in 'club_cash_transaction[amount]', :with => "99"
    alert_ok_js
    click_on 'Save club cash transaction'
    sleep 0.5
    within("#table_membership_information"){
      within("#td_mi_club_cash_amount"){
          assert page.has_content?('99.0')
      }
    }
    @saved_user.set_as_canceled
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_membership_information"){
      within("#td_mi_club_cash_expire_date"){
          assert page.has_content?('')
      }
    }
  end

  test "set club cash expire date on user created by sloop once it is billed" do
    setup_user false
    @enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    @credit_card = FactoryBot.build :credit_card
    @user = FactoryBot.build :user_with_api

    create_user_by_sloop(@admin_agent, @user, @credit_card, @enrollment_info, @terms_of_membership_with_gateway)
    @saved_user = User.find_by_email(@user.email)
    @saved_user.bill_membership
    @saved_user.reload
  
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    @saved_user.reload
    within("#table_membership_information") do
      within("#td_mi_club_cash_expire_date") do

        assert page.has_content?(I18n.l(@saved_user.club_cash_expire_date, :format => :only_date))
      end
    end
  end

  test "add club cash amount using the amount on user TOM enrollment amount = 0" do
    enrollment_info = FactoryBot.build(:membership_with_enrollment_info)
    @partner = FactoryBot.create(:partner)
    @club = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway, :club_id => @club.id)

    create_user_throught_sloop(enrollment_info, @terms_of_membership_with_gateway)
    @saved_user = User.last
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?('0.0')
      end
    end
    current_club_cash = @saved_user.club_cash_amount
    @saved_user.current_membership.update_attribute :join_date, Time.zone.now-23.months
    @saved_user.update_attribute :next_retry_bill_date, Time.zone.now
    @saved_user.bill_membership
    @saved_user.reload
    assert_equal(@saved_user.club_cash_amount, current_club_cash + @terms_of_membership_with_gateway.club_cash_installment_amount )
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?((current_club_cash + @terms_of_membership_with_gateway.club_cash_installment_amount).to_s)
      end
      within("#td_mi_club_cash_expire_date")do
        assert page.has_content?(I18n.l(@saved_user.club_cash_expire_date, :format => :only_date))
      end
    end
  end

  test "add club cash from club cash amount configured in the TOM - Monthly user" do
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)

    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?('0.0')
      end
    end
    current_club_cash = @saved_user.club_cash_amount
    @saved_user.current_membership.update_attribute :join_date, Time.zone.now-23.months
    @saved_user.bill_membership 
    @saved_user.reload
    assert_equal(@saved_user.club_cash_amount, (current_club_cash + @terms_of_membership_with_gateway.club_cash_installment_amount) )
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?((current_club_cash + @terms_of_membership_with_gateway.club_cash_installment_amount).to_s)
      end
      within("#td_mi_club_cash_expire_date")do
        assert page.has_content?(I18n.l(@saved_user.club_cash_expire_date, :format => :only_date))
      end
    end    
  end

  test "add club cash from club cash amount configured in the TOM - Yearly user" do
    setup_user false
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    @saved_user = create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent })
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?('0.0')
      end
    end
    current_club_cash = @saved_user.club_cash_amount
    @saved_user.current_membership.update_attribute :join_date, Time.zone.now-23.months
    @saved_user.bill_membership
    @saved_user.reload
    assert_equal(@saved_user.club_cash_amount, (current_club_cash + @terms_of_membership_with_gateway.club_cash_installment_amount) )
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?((current_club_cash + @terms_of_membership_with_gateway.club_cash_installment_amount).to_s)
      end
      within("#td_mi_club_cash_expire_date")do
        assert page.has_content?(I18n.l(@saved_user.club_cash_expire_date, :format => :only_date))
      end
    end
  end

  test "Add club cash from club cash amount configured in the TOM - Yearly and Chapter user" do
    setup_user false
    @terms_of_membership_with_gateway = FactoryBot.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    @saved_user = create_active_user(@terms_of_membership_with_gateway, :active_user, nil, {}, { :created_by => @admin_agent })
    @saved_user.update_attribute(:country, "US")
    @saved_user.update_attribute(:state, "AL")
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    click_link_or_button('Edit')
    select('VIP', :from => 'user[member_group_type_id]')
    alert_ok_js
    click_link_or_button('Update User')
    assert find_field('input_first_name').value == @saved_user.first_name
    @saved_user.reload
    @saved_user.current_membership.update_attribute :join_date, Time.zone.now-12.months
    @saved_user.bill_membership
    @saved_user.reload
    assert_equal(@saved_user.club_cash_amount, @saved_user.terms_of_membership.club_cash_installment_amount )
    @saved_user.reload
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?(@saved_user.terms_of_membership.club_cash_installment_amount.to_s)
      end
      within("#td_mi_club_cash_expire_date")do
        assert page.has_content?(I18n.l(@saved_user.club_cash_expire_date, :format => :only_date))
      end
    end
  end  

  test "club cash Renewal" do
    setup_user
    @saved_user.bill_membership
    @saved_user.reload
    @saved_user.club_cash_expire_date = Date.today - 1
    @saved_user.save
    date = @saved_user.club_cash_expire_date
    @saved_user.reset_club_cash
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    assert find_field('input_first_name').value == @saved_user.first_name
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?('0.0')
      end
      within("#td_mi_club_cash_expire_date")do
        assert page.has_content?(I18n.l(date+1.year, :format => :only_date))
      end
    end
  end

  test "Check club cash amount on membership show at CS" do
    setup_user
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_membership_information")do
      click_link_or_button(@terms_of_membership_with_gateway.name)
    end 
    within("#div_description_feature") do   
      assert page.has_content? "#{I18n.t('activerecord.attributes.terms_of_membership.initial_club_cash_amount')}: #{@terms_of_membership_with_gateway.initial_club_cash_amount.to_s}"
      assert page.has_content? "#{I18n.t('activerecord.attributes.terms_of_membership.club_cash_installment_amount')}: #{@terms_of_membership_with_gateway.club_cash_installment_amount.to_s}"
      assert page.has_content? "#{I18n.t('activerecord.attributes.terms_of_membership.skip_first_club_cash')}: #{@terms_of_membership_with_gateway.skip_first_club_cash ? 'Yes' : 'No'}"
    end
  end

  test "Should not show anything related to club cash when club does not allow it." do
    setup_user
    @club.update_attribute :club_cash_enable, false
    visit show_user_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :user_prefix => @saved_user.id)
    within("#table_membership_information") do
      assert page.has_no_content?( I18n.t('activerecord.attributes.user.club_cash_amount') )
      assert page.has_no_selector?( I18n.t('activerecord.attributes.user.add_club_cash_transaction') )
      assert page.has_no_content?( I18n.t('activerecord.attributes.user.add_club_cash_transaction') )
    end
    within(".nav-tabs"){ assert page.has_no_content?("Club Cash") }
  end
end