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
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @payment_gateway_configuration = FactoryGirl.create(:payment_gateway_configuration, :club_id => @club.id)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    @saved_member = FactoryGirl.create(:active_member, :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent)
		@saved_member.reload
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

  test "add club cash amount" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    
    click_on 'Add club cash'
    
    alert_ok_js
    fill_in '[amount]', :with => "15"  
    click_on 'Save club cash transaction'
    within("#td_mi_club_cash_amount") { assert page.has_content?("15") }

    within("#operations_table") do
      wait_until {
        assert page.has_content?("15 club cash was successfully added")
      }
    end

    click_on 'Add club cash'
    
    alert_ok_js
    fill_in '[amount]', :with => "-5"  
    click_on 'Save club cash transaction'
    within("#td_mi_club_cash_amount") { assert page.has_content?("10") }

    within("#operations_table") do
      wait_until {
        assert page.has_content?("5 club cash was successfully deducted")
      }
    end

  end


  test "club cash amount can't be negatibe" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    
    click_on 'Add club cash'
    
    alert_ok_js
    fill_in '[amount]', :with => "15"  
    click_on 'Save club cash transaction'
    
    within("#td_mi_club_cash_amount") { assert page.has_content?("15") }

    click_on 'Add club cash'
    fill_in '[amount]', :with => "-20"
    alert_ok_js
    click_on 'Save club cash transaction'

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within("#td_mi_club_cash_amount") { assert page.has_content?("15") }

  end

  test "invalid characters on club cash" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Add club cash'

    fill_in '[amount]', :with => "random text"
    alert_ok_js
    click_on 'Save club cash transaction'

    wait_until{
      assert page.has_content?('Can not process club cash transaction with amount 0, values with commas, or letters.')
    }
  end

  test "add club cash with ammount 0" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Add club cash'

    fill_in '[amount]', :with => "0"
    alert_ok_js
    click_on 'Save club cash transaction'

    wait_until{
      assert page.has_content?('Can not process club cash transaction with amount 0, values with commas, or letters.')
    }
  end

  test "add club cash with float ammount" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Add club cash'
    fill_in '[amount]', :with => "0.99"
    alert_ok_js
    click_on 'Save club cash transaction'

    wait_until{
      assert page.has_content?('Can not process club cash transaction with amount 0, values with commas, or letters.')
    }

  end

  test "create member with terms_of_membership without club cash" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id, :name => 'club_testing_')
    Time.zone = @club.time_zone
    @payment_gateway_configuration = FactoryGirl.create(:payment_gateway_configuration, :club_id => @club.id)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway_without_club_cash, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)

    @saved_member = FactoryGirl.create(:active_member, 
      :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent)
    @saved_member.reload

    sign_in_as(@admin_agent)
    @saved_member.bill_membership
    sleep(3) #To wait until billing is finished.
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  
    within("#operations_table")do
      wait_until{
        assert page.has_no_content?('0 club cash was successfully added')
      }
    end
  end

  test "member cancelation must set to 0 the club cash" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Add club cash'
    fill_in '[amount]', :with => "99"
    alert_ok_js
    click_on 'Save club cash transaction'

    within("#table_membership_information"){
      within("#td_mi_club_cash_amount"){
        wait_until{
          assert page.has_content?('99.0')
        }
      }
    }

    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within("#table_membership_information"){
      within("#td_mi_club_cash_amount"){
        wait_until{
          assert page.has_content?('0')
        }
      }
    }
  end 

  test "member cancelation must set club cash expired day as nil" do
    setup_member
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    click_on 'Add club cash'
    fill_in '[amount]', :with => "99"
    alert_ok_js
    click_on 'Save club cash transaction'

    within("#table_membership_information"){
      within("#td_mi_club_cash_amount"){
        wait_until{
          assert page.has_content?('99.0')
        }
      }
    }

    @saved_member.set_as_canceled
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    within("#table_membership_information"){
      within("#td_mi_club_cash_expire_date"){
        wait_until{
          assert page.has_content?('')
        }
      }
    }
  end

  test "set club cash expire date on member created by sloop once it is billed" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id, :name => 'dasd')
    @payment_gateway_configuration = FactoryGirl.create(:payment_gateway_configuration, :club_id => @club.id)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @credit_card = FactoryGirl.build :credit_card
    @member = FactoryGirl.build :member_with_api
    @enrollment_info = FactoryGirl.build(:enrollment_info)
    
    create_member_by_sloop(@admin_agent, @member, @credit_card, @enrollment_info, @terms_of_membership_with_gateway)

    sign_in_as @admin_agent
    @saved_member = Member.find_by_email(@member.email)
    @saved_member.bill_membership
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
    }
    @saved_member.reload
    within("#table_membership_information"){
      within("#td_mi_club_cash_expire_date"){
        wait_until{
          assert page.has_content?(I18n.l(@saved_member.club_cash_expire_date, :format => :only_date))
        }
      }
    }
  end

  test "add club cash with member created by sloop" do
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @payment_gateway_configuration = FactoryGirl.create(:payment_gateway_configuration, :club_id => @club.id)
    enrollment_info = FactoryGirl.build(:complete_enrollment_info_with_cero_amount)
  
    create_member_throught_sloop(enrollment_info, @terms_of_membership_with_gateway)

    @saved_member = Member.last

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        wait_until{
          assert page.has_content?('0.0')
        }
      end
    end
    wait_until{ assert @saved_member.club_cash_expire_date == nil }

    @saved_member.bill_membership 
    wait_until{ assert_equal(@saved_member.club_cash_amount, @terms_of_membership_with_gateway.club_cash_amount ) }
    @saved_member.reload

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        wait_until{
          assert page.has_content?(@terms_of_membership_with_gateway.club_cash_amount.to_s)
        }
      end
      within("#td_mi_club_cash_expire_date")do
        wait_until{
          assert page.has_content?(I18n.l(@saved_member.club_cash_expire_date, :format => :only_date))
        }
      end
    end
  end

  test "add club cash from club cash amount configured in the TOM - Monthly Member" do
    setup_member

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        wait_until{
          assert page.has_content?('0.0')
        }
      end
    end
    wait_until{ assert @saved_member.club_cash_expire_date == nil }

    @saved_member.bill_membership 
    wait_until{ assert_equal(@saved_member.club_cash_amount, @terms_of_membership_with_gateway.club_cash_amount ) }
    @saved_member.reload

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        wait_until{
          assert page.has_content?(@terms_of_membership_with_gateway.club_cash_amount.to_s)
        }
      end
      within("#td_mi_club_cash_expire_date")do
        wait_until{
          assert page.has_content?(I18n.l(@saved_member.club_cash_expire_date, :format => :only_date))
        }
      end
    end    
  end

  test "add club cash from club cash amount configured in the TOM - Yearly Member" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @payment_gateway_configuration = FactoryGirl.create(:payment_gateway_configuration, :club_id => @club.id)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    @saved_member = FactoryGirl.create(:active_member, :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent)
    @saved_member.reload
    sign_in_as(@admin_agent)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        wait_until{
          assert page.has_content?('0.0')
        }
      end
    end
    wait_until{ assert @saved_member.club_cash_expire_date == nil }

    @saved_member.bill_membership 
    wait_until{ assert_equal(@saved_member.club_cash_amount, @terms_of_membership_with_gateway.club_cash_amount ) }
    @saved_member.reload

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        wait_until{
          assert page.has_content?(@terms_of_membership_with_gateway.club_cash_amount.to_s)
        }
      end
      within("#td_mi_club_cash_expire_date")do
        wait_until{
          assert page.has_content?(I18n.l(@saved_member.club_cash_expire_date, :format => :only_date))
        }
      end
    end
  end

  test "Add club cash from club cash amount configured in the TOM - Yearly and Chapter Member" do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    Time.zone = @club.time_zone
    @payment_gateway_configuration = FactoryGirl.create(:payment_gateway_configuration, :club_id => @club.id)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway_yearly, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    @saved_member = FactoryGirl.create(:active_member, :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent)
    @saved_member.reload
    sign_in_as(@admin_agent)

    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    click_link_or_button('Edit')
    
    select('VIP', :from => 'member[member_group_type_id]')
    alert_ok_js
    click_link_or_button('Update Member')
    wait_until{
      assert find_field('input_first_name').value == @saved_member.first_name
    }
    @saved_member.reload
    @saved_member.bill_membership 
    wait_until{ assert_equal(@saved_member.club_cash_amount, 200 ) }
    @saved_member.reload
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)

    within("#table_membership_information")do
      within("#td_mi_club_cash_amount")do
        wait_until{
          assert page.has_content?('200.0')
        }
      end
      within("#td_mi_club_cash_expire_date")do
        wait_until{
          assert page.has_content?(I18n.l(@saved_member.club_cash_expire_date, :format => :only_date))
        }
      end
    end
  end  

  # FixME : Rake::Task does not work.
  # test "club cash Renewal" do
  #   setup_member
  #   @saved_member.bill_membership
  #   @saved_member.club_cash_expire_date = Date.today - 1.day
  #   @saved_member.save
  #   Rake::Task['members:process_club_cash'].invoke
  #   visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
  
  #   sleep(50)
  # end

end

