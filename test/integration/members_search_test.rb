require 'test_helper' 
 
class MembersSearchTest < ActionController::IntegrationTest
 
  setup do
    init_test_setup
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    @terms_of_membership_with_gateway = FactoryGirl.create(:terms_of_membership_with_gateway)
    10.times{ FactoryGirl.create(:active_member, 
      :club_id => @club.id, 
      :terms_of_membership => @terms_of_membership_with_gateway,
      :created_by => @admin_agent) }

    @search_member = Member.first
    sign_in_as(@admin_agent)
    visit members_path(:partner_prefix => @partner.prefix, :club_prefix => @club.name)
  end

  def search_member(field_selector, value, validate_obj)
    fill_in field_selector, :with => value unless value.nil?
    click_on 'Search'
    within("#members") do
      wait_until {
        assert page.has_content?(validate_obj.status)
        assert page.has_content?("#{validate_obj.visible_id}")
        assert page.has_content?(validate_obj.full_name)
        assert page.has_content?(validate_obj.full_address)
      }
    end
  end
  
  test "search member by member id" do
    search_member("member[member_id]", "#{@search_member.visible_id}", @search_member)
  end

  test "search member by first name" do
    search_member("member[first_name]", "#{@search_member.first_name}", @search_member)
  end

  test "search members by next bill date" do
    page.execute_script("window.jQuery('#member_next_retry_bill_date').next().click()")
    within("#ui-datepicker-div") do
      click_on("#{Time.new.day}")
    end
    search_member("member[next_retry_bill_date]", nil, @search_member)
  end
  
  test "display member" do
    search_member("member[member_id]", "#{@search_member.visible_id}", @search_member)
    within("#members") do
      wait_until {
        assert page.has_content?("#{@search_member.visible_id}")
      }
    end
    page.execute_script("window.jQuery('.odd:first a:first').find('.icon-zoom-in').click()")
    
    assert find_field('input_visible_id').value == "#{@search_member.visible_id}"
    assert find_field('input_first_name').value == @search_member.first_name
    assert find_field('input_last_name').value == @search_member.last_name
    assert find_field('input_gender').value == (@search_member.gender == 'F' ? 'Female' : 'Male')
    assert find_field('input_member_group_type').value == (@search_member.member_group_type.nil? ? I18n.t('activerecord.attributes.member.not_group_associated') : @search_member.member_group_type.name)
    
    within("#table_demographic_information") do
      assert page.has_content?(@search_member.address)
      assert page.has_content?(@search_member.city)
      assert page.has_content?(@search_member.state)
      assert page.has_content?(@search_member.country)
      assert page.has_content?(@search_member.zip)
      assert page.has_selector?('#link_member_set_undeliverable')     
    end

    within("#table_contact_information") do
      assert page.has_content?(@search_member.full_phone_number)
      assert page.has_content?(@search_member.type_of_phone_number)
      assert page.has_content?("#{@search_member.birth_date}")
      assert page.has_selector?('#link_member_set_unreachable')     
    end

    active_credit_card = @search_member.active_credit_card
    within("#table_active_credit_card") do
      assert page.has_content?("#{active_credit_card.number}")
      assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
    end

    within("#table_membership_information") do
      assert page.has_content?(@search_member.status)
      within("#td_mi_member_since_date") { assert page.has_content?(I18n.l(@search_member.member_since_date, :format => :only_date)) }
      
      assert page.has_content?(@search_member.terms_of_membership.name)
      
      within("#td_mi_reactivation_times") { assert page.has_content?("#{@search_member.reactivation_times}") }
      
      assert page.has_content?(@search_member.created_by.username)

      within("#td_mi_reactivation_times") { assert page.has_content?("#{@search_member.reactivation_times}") }
      
      within("#td_mi_recycled_times") { assert page.has_content?("#{@search_member.recycled_times}") }
      
      assert page.has_no_selector?("#td_mi_external_id")
      
      within("#td_mi_join_date") { assert page.has_content?(I18n.l(@search_member.join_date, :format => :only_date)) }

      within("#td_mi_next_retry_bill_date") { assert page.has_content?("#{@search_member.next_retry_bill_date}") }

      assert page.has_selector?("#link_member_change_next_bill_date")

      within("#td_mi_club_cash_amount") { assert page.has_content?("#{@search_member.club_cash_amount.to_f}") }

      within("#td_mi_credit_cards_first_created_at") { assert page.has_content?(I18n.l(@search_member.credit_cards.first.created_at, :format => :only_date)) }

      within("#td_mi_quota") { assert page.has_content?("#{@search_member.quota}") }
      
    end    
    
    within("#operations_table") { assert page.has_content?("No data available in table") }

    within("#credit_cards") { 
      assert page.has_content?("#{active_credit_card.number}") 
      assert page.has_content?("#{active_credit_card.expire_month} / #{active_credit_card.expire_year}")
    }

    within("#transactions_table") { assert page.has_content?("No data available in table") }

    within("#fulfillments") { assert page.has_content?("No fulfillments were found") }

    within("#communication") { assert page.has_content?("No communications were found") }

    
  end



end