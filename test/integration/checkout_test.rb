require 'test_helper' 

class CheckoutTest < ActionDispatch::IntegrationTest
 
  setup do
    @landing_agent = FactoryGirl.create(:confirmed_landing_agent)   
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    host = Capybara.current_session.server.host
    port = Capybara.current_session.server.port
    @club.checkout_url = "http://#{host}:#{port}"
    @club.save(validate: false)
    @terms_of_membership = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @campaign = FactoryGirl.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id)       
    @prospect = FactoryGirl.create(:prospect, :club_id => @club.id, :campaign_id => @campaign.id, :terms_of_membership_id => @terms_of_membership.id)
    @credit_card = FactoryGirl.create :credit_card_american_express  
    sign_in_as(@landing_agent)
  end

  def show_new_checkout(prospect)    
    visit new_checkout_path(campaign_id:@campaign.to_param, token: prospect.token)    
    assert page.has_content?("Name #{prospect.first_name} #{prospect.last_name}")    
    assert page.has_content?("Address #{prospect.address}")
    assert page.has_content?("Email #{prospect.email}")
    assert page.has_content?("City / State / Zip #{prospect.city} / #{prospect.state} / #{prospect.zip}") 
    assert page.has_content?("Shipping & Processing $#{@campaign.enrollment_price}")
  end

  def fill_in_credit_card(number, expire_month, expire_year)
    fill_in 'credit_card[number]', with: number
    select expire_month, :from => 'credit_card[expire_month]'
    select expire_year, :from => 'credit_card[expire_year]'   
  end

  test "create a user and show Thanks You web page" do   
    show_new_checkout(@prospect) 
    assert_difference('User.count',1) do
      fill_in_credit_card(@credit_card.number, @credit_card.expire_month, @credit_card.expire_year)
      click_link_or_button 'Submit'
    end    
    assert page.has_content?("Thank you for your order!")
  end

  test "show Duplicated web page" do
    user = FactoryGirl.create(:user, :club_id => @club.id)
    prospect = FactoryGirl.create(:prospect, :email => user.email, :club_id => @club.id, :campaign_id => @campaign.id, :terms_of_membership_id => @terms_of_membership.id)    
    show_new_checkout(prospect) 
    assert_difference('User.count',0) do
      fill_in_credit_card(@credit_card.number, @credit_card.expire_month, @credit_card.expire_year)
      click_link_or_button 'Submit'   
    end 
    assert page.has_content?("Duplicated Member")
  end

  test "show Error web page" do    
    prospect = FactoryGirl.create(:prospect, :first_name => 'first_name', :club_id => @club.id, :campaign_id => @campaign.id, :terms_of_membership_id => @terms_of_membership.id)    
    show_new_checkout(prospect) 
    assert_difference('User.count',0) do
      fill_in_credit_card(@credit_card.number, @credit_card.expire_month, @credit_card.expire_year)
      click_link_or_button 'Submit'   
    end 
    assert page.has_content?("Error!")
    assert page.has_content?("There seems to be a problem with your payment information.")
  end

  test "do not create a user when it does not enter credit card" do    
    visit new_checkout_path(campaign_id: @campaign.to_param, token: @prospect.token)
    click_link_or_button 'Submit'   
    assert page.has_content?("Can't be blank.")    
  end

  test "do not create a user when it enter expired CC" do  
    if not Time.now.month == 1    
      visit new_checkout_path(campaign_id:@campaign.to_param, token: @prospect.token)       
      fill_in_credit_card(@credit_card.number, 01, Time.now.year)
      click_link_or_button 'Submit'  
      assert page.has_content?("Your credit card has expired")    
    end
  end

  test "do not create a user when it enter invalid CC" do     
    visit new_checkout_path(campaign_id:@campaign.to_param, token: @prospect.token)
    fill_in_credit_card(445124454477885445555, @credit_card.expire_month, @credit_card.expire_year)
    click_link_or_button 'Submit'
    assert page.has_content?("Please enter a valid credit card number.")      
  end
end