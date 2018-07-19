require 'test_helper' 

class CampaignProductTest < ActionDispatch::IntegrationTest
 
  setup do
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    @partner = FactoryBot.create(:partner)    
    @club = FactoryBot.create(:simple_club_with_gateway, :partner_id => @partner.id)    
    @terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway, :club_id => @club.id)
    @campaign = FactoryBot.create(:campaign, :club_id => @club.id, :terms_of_membership_id => @terms_of_membership.id )                 
    sign_in_as(@admin_agent)
  end

  test "should assign products to campaign" do
    visit campaign_products_edit_path(@partner.prefix, @club.name, @campaign.id) 
    within("#available_products_table") do      
      assert_difference('CampaignProduct.count') do 
        click_link_or_button 'Assign'       
      end
    end
    assert_equal((@campaign.products), @club.products, 'Campaign is not able to assign a product')
  end

  test "should remove products from campaign" do 
    @campaign.products << @club.products          
    visit campaign_products_edit_path(@partner.prefix, @club.name, @campaign.id)
    within("#assigned_products_table") do
      assert_difference('CampaignProduct.count', -1) do
        click_link_or_button 'Remove'
      end
    end  
  end

  test "should rename products label" do    
    @product = FactoryBot.create(:random_product, :club_id => @club.id)
    @campaign.products << @product       
    visit campaign_products_edit_path(@partner.prefix, @club.name, @campaign.id)
    within("#assigned_products_table") do
      click_link_or_button 'Rename'
    end
    rename = 'name to see in the landing'
    fill_in 'campaign_product[label]', with: rename
    click_link_or_button 'Set Product Label'
    assert_equal(CampaignProduct.find_by(@campaign.id).label, rename, 'Campaign is not able to rename the product')
    assert page.has_content?("Label for #{@product.name} for Campaign #{@campaign.name} was set successfuly.")           
  end

  test "Should reset product label" do
    @product = FactoryBot.create(:random_product, :club_id => @club.id)
    @campaign.products << @product         
    visit campaign_products_edit_path(@partner.prefix, @club.name, @campaign.id)
    within("#assigned_products_table") do
      click_link_or_button 'Rename'
    end
    rename = 'name to see in the landing'
    fill_in 'campaign_product[label]', with: rename
    click_link_or_button 'Reset Product Label'
    click_link_or_button 'Set Product Label'
    assert_equal(CampaignProduct.find_by(@campaign.id).label, @product.name, 'Campaign is not able to reset product label')
    assert page.has_content?("Label for #{@product.name} for Campaign #{@campaign.name} was set successfuly.")           
  end
end