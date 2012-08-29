require 'test_helper'
 
class MembersBillTest < ActionController::IntegrationTest


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
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @communication_type = FactoryGirl.create(:communication_type)
    @disposition_type = FactoryGirl.create(:disposition_type, :club_id => @club.id)
    FactoryGirl.create(:batch_agent)
    
    @saved_member = FactoryGirl.create(:active_member, 
        :club_id => @club.id, 
        :terms_of_membership => @terms_of_membership_with_gateway,
        :created_by => @admin_agent)

    @saved_member.reload
    
    sign_in_as(@admin_agent)
  end



  ############################################################
  # UTILS
  ############################################################
  def validate_cohort(member, enrollment_info, transaction)
    str = "#{member.join_date.year}-#{member.join_date.month}-#{enrollment_info.mega_channel}-#{enrollment_info.campaign_medium}"
    assert transaction.cohort == str, "validate_cohort error"
  end

  ############################################################
  # TEST
  ############################################################

  test "create a member billing enroll > 0" do
    active_merchant_stubs
    setup_member
    enrollment_info = FactoryGirl.create(:complete_enrollment_info_with_amount, :member_id => @saved_member.id)
    answer = @saved_member.bill_membership
    assert (answer[:code] == Settings.error_codes.success), answer[:message]
    visit show_member_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name, :member_prefix => @saved_member.visible_id)
    
    next_bill_date = @saved_member.join_date + eval(@terms_of_membership_with_gateway.installment_type)
    
    within("#td_mi_club_cash_amount") { assert page.has_content?("#{@terms_of_membership_with_gateway.club_cash_amount}") }

    within("#td_mi_next_retry_bill_date") { assert page.has_content?(I18n.l(next_bill_date, :format => :only_date)) }

    within("#transactions_table") do 
      wait_until {
        assert page.has_content?("This transaction has been approved")
      }
    end

    within("#operations_table") do
      wait_until {
        assert page.has_content?("Member billed successfully $#{@terms_of_membership_with_gateway.installment_amount}") 
      }
    end
 
    validate_cohort(@saved_member, enrollment_info, Transaction.last)
 
  end 

end