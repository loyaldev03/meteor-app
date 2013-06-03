require 'test_helper'
 
class MembersClubCashTest < ActionController::IntegrationTest

  ############################################################
  # SETUP
  ############################################################

  setup do
    init_test_setup
  end

  def setup_member
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
    sign_in_as(@admin_agent)
  end

  def create_member_throught_sloop(enrollment_info, terms_of_membership)
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    Time.zone = @club.time_zone

    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    create_member_by_sloop(@admin_agent, @member, @credit_card, enrollment_info, terms_of_membership)
    sign_in_as(@admin_agent)
  end

  ###########################################################
  # TESTS
  ###########################################################

  # # Remove/Add Club Cash
  # See club cash transaction history (Only Clubs without Drupal domain)

  # test "Message after Club Cash addition" do
  #   setup_member

  #   visit show_member_path(:partner_prefix => @saved_member.club.partner.prefix, :club_prefix => @saved_member.club.name, :member_prefix => @saved_member.id)
  #   within("#table_membership_information"){ click_on 'Add club cash' }

  #   fill_in 'club_cash_transaction[amount]', :with => 5
  #   fill_in 'club_cash_transaction[description]', :with => "description"
  #   click_on 'Save club cash transaction'
  #   sleep 1
  #   page.driver.browser.switch_to.alert.accept 
    # console error: NoMethodError: undefined method `username' for nil:NilClass
    # /home/pablo/Documents/sac-platform/app/datatables/operations_datatable.rb:14:in `data'
    # /home/pablo/Documents/sac-platform/app/datatables/datatable.rb:18:in `as_json'
  # end

  test "add club cash amount" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    add_club_cash(@saved_member, 15, "Generic description")
    @saved_member.reload
    add_club_cash(@saved_member, -5, "Generic description")
  end

  test "club cash amount can't be negatibe" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    add_club_cash(@saved_member, 15, "Generic description")
    add_club_cash(@saved_member, -20, "Deducting more than member has.", false)
    assert page.has_content?("You can not deduct 20 because the member only has 15 club cash.")
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#td_mi_club_cash_amount") { assert page.has_content?("15") }
  end

  # Error message when adding a wrong club cash

  test "invalid characters on club cash" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_on 'Add club cash'
    fill_in 'club_cash_transaction[amount]', :with => "random text"
    alert_ok_js
    click_on 'Save club cash transaction'
    assert page.has_content?(I18n.t("error_messages.club_cash_transaction_invalid_amount"))
  end

  test "add club cash with ammount 0" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_on 'Add club cash'
    fill_in 'club_cash_transaction[amount]', :with => "0"
    alert_ok_js
    click_on 'Save club cash transaction'
    assert page.has_content?('Can not process club cash transaction with amount 0 or letters.')
  end

  test "add club cash with float ammount" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_on 'Add club cash'
    fill_in 'club_cash_transaction[amount]', :with => "0.99"
    alert_ok_js
    click_on 'Save club cash transaction'
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#td_mi_club_cash_amount") { assert page.has_content?("0.99") }
    within("#operations_table")do
      assert page.has_content?('0.99 club cash was successfully added. Concept:')
    end
  end

  test "create member with terms_of_membership without club cash" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id, :name => 'club_testing_')
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway_without_club_cash, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
    sign_in_as(@admin_agent)
    @saved_member.bill_membership
    sleep(1) #To wait until billing is finished.
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#operations_table")do
      assert page.has_no_content?('0 club cash was successfully added. Concept:')
    end
  end

  test "member cancelation must set to 0 the club cash" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_on 'Add club cash'
    fill_in 'club_cash_transaction[amount]', :with => "99"
    alert_ok_js
    click_on 'Save club cash transaction'
    within("#table_membership_information"){
      within("#td_mi_club_cash_amount"){
          assert page.has_content?('99.0')
      }
    }
    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information"){
      within("#td_mi_club_cash_amount"){
          assert page.has_content?('0')
      }
    }
  end 

  test "member cancelation must set club cash expired day as nil" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_on 'Add club cash'
    fill_in 'club_cash_transaction[amount]', :with => "99"
    alert_ok_js
    click_on 'Save club cash transaction'
    within("#table_membership_information"){
      within("#td_mi_club_cash_amount"){
          assert page.has_content?('99.0')
      }
    }
    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information"){
      within("#td_mi_club_cash_expire_date"){
          assert page.has_content?('')
      }
    }
  end

  test "set club cash expire date on member created by sloop once it is billed" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id, :name => 'dasd')
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build(:enrollment_info)
    create_member_by_sloop(@admin_agent, @member, @credit_card, @enrollment_info, @terms_of_membership_with_gateway)
    sign_in_as @admin_agent
    @saved_member = Member.find_by_email(@member.email)
    @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    @saved_member.reload
    within("#table_membership_information") do
      within("#td_mi_club_cash_expire_date") do
        assert page.has_content?(I18n.l(@saved_member.club_cash_expire_date, :format => :only_date))
      end
    end
  end

  test "add club cash amount using the amount on member TOM enrollment amount > 0" do
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:complete_enrollment_info_with_cero_amount)
    create_member_throught_sloop(enrollment_info, @terms_of_membership_with_gateway)
    @saved_member = Member.last
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?('0.0')
      end
    end
    assert @saved_member.club_cash_expire_date == nil
    @saved_member.bill_membership 
    assert_equal(@saved_member.club_cash_amount, @terms_of_membership_with_gateway.club_cash_amount )
    @saved_member.reload
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?(@terms_of_membership_with_gateway.club_cash_amount.to_s)
      end
      within("#td_mi_club_cash_expire_date")do
        assert page.has_content?(I18n.l(@saved_member.club_cash_expire_date, :format => :only_date))
      end
    end
  end

  test "add club cash from club cash amount configured in the TOM - Monthly Member" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?('0.0')
      end
    end
    assert @saved_member.club_cash_expire_date == nil
    @saved_member.bill_membership 
    assert_equal(@saved_member.club_cash_amount, @terms_of_membership_with_gateway.club_cash_amount )
    @saved_member.reload
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?(@terms_of_membership_with_gateway.club_cash_amount.to_s)
      end
      within("#td_mi_club_cash_expire_date")do
        assert page.has_content?(I18n.l(@saved_member.club_cash_expire_date, :format => :only_date))
      end
    end    
  end

  test "add club cash from club cash amount configured in the TOM - Yearly Member" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
    sign_in_as(@admin_agent)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?('0.0')
      end
    end
    assert @saved_member.club_cash_expire_date == nil
    @saved_member.bill_membership 
    assert_equal(@saved_member.club_cash_amount, @terms_of_membership_with_gateway.club_cash_amount )
    @saved_member.reload
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?(@terms_of_membership_with_gateway.club_cash_amount.to_s)
      end
      within("#td_mi_club_cash_expire_date")do
        assert page.has_content?(I18n.l(@saved_member.club_cash_expire_date, :format => :only_date))
      end
    end
  end

  test "Add club cash from club cash amount configured in the TOM - Yearly and Chapter Member" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    @saved_member = create_active_member(@terms_of_membership_with_gateway, :active_member, nil, {}, { :created_by => @admin_agent })
    @saved_member.update_attribute(:country, "US")
    @saved_member.update_attribute(:state, "AL")
    sign_in_as(@admin_agent)
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    click_link_or_button('Edit')
    select('VIP', :from => 'member[member_group_type_id]')
    alert_ok_js
    click_link_or_button('Update Member')
    assert find_field('input_first_name').value == @saved_member.first_name
    @saved_member.reload
    @saved_member.bill_membership 
    assert_equal(@saved_member.club_cash_amount, 200 )
    @saved_member.reload
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?('200.0')
      end
      within("#td_mi_club_cash_expire_date")do
        assert page.has_content?(I18n.l(@saved_member.club_cash_expire_date, :format => :only_date))
      end
    end
  end  

  test "club cash Renewal" do
    setup_member
    @saved_member.bill_membership
    @saved_member.club_cash_expire_date = Date.today - 1
    @saved_member.save
    date = @saved_member.club_cash_expire_date
    @saved_member.reset_club_cash
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    assert find_field('input_first_name').value == @saved_member.first_name
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?('0.0')
      end
      within("#td_mi_club_cash_expire_date")do
        assert page.has_content?(I18n.l(date+1.year, :format => :only_date))
      end
    end
  end

  test "Add club cash amount using the amount on member TOM enrollment amount = 0" do
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:complete_enrollment_info_with_cero_amount)
    create_member_throught_sloop(enrollment_info, @terms_of_membership_with_gateway)
    @saved_member = Member.last
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?('0.0')
      end
    end
    assert @saved_member.club_cash_expire_date == nil
    @saved_member.bill_membership 
    assert_equal(@saved_member.club_cash_amount, @terms_of_membership_with_gateway.club_cash_amount )
    @saved_member.reload
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        assert page.has_content?(@terms_of_membership_with_gateway.club_cash_amount.to_s)
      end
      within("#td_mi_club_cash_expire_date")do
        assert page.has_content?(I18n.l(@saved_member.club_cash_expire_date, :format => :only_date))
      end
    end
  end

  test "Check club cash amount on membership show at CS" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information")do
      click_link_or_button(@terms_of_membership_with_gateway.name)
    end 
    page.has_content?(@terms_of_membership_with_gateway.club_cash_amount.to_s)
  end

  test "Should not show anything related to club cash when club does not allow it." do
    setup_member
    @club.update_attribute :club_cash_enable, false
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.id)
    within("#table_membership_information") do
      assert page.has_no_content?( I18n.t('activerecord.attributes.member.club_cash_amount') )
      assert page.has_no_selector?( I18n.t('activerecord.attributes.member.add_club_cash_transaction') )
      assert page.has_no_content?( I18n.t('activerecord.attributes.member.add_club_cash_transaction') )
    end
    within(".nav-tabs"){ assert page.has_no_content?("Club Cash") }
  end
end

