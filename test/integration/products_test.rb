require 'test_helper'

class ProductsTest < ActionDispatch::IntegrationTest

  setup do
    SacStore.enable_integration!
    @admin_agent = FactoryBot.create(:confirmed_admin_agent)
    @partner = FactoryBot.create(:partner)
    @club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    @transport_settings = FactoryBot.create(:transport_settings_store, club_id: @club.id)
    sign_in_as(@admin_agent)
  end

  test "product list" do
    saved_product = FactoryBot.create(:random_product, club_id: @club.id) 
    visit products_path(@partner.prefix, @club.name)

    within("#products_table") do
      assert page.has_content?(saved_product.name)
      assert page.has_content?(saved_product.sku.to_s)
      assert page.has_content?(saved_product.stock.to_s)
      assert page.has_content?(saved_product.allow_backorder ? 'Yes' : 'No')
    end
  end

  test "all links in product show must work" do
    saved_product = FactoryBot.create(:random_product, club_id: @club.id)
    visit products_path(@partner.prefix, @club.name)     
    assert page.has_content?('Search')
    visit product_path(@partner.prefix, @club.name, saved_product.id)
    click_link_or_button 'Back'   
  end

  test "update a product when click on Import data button" do        
    visit products_path(@partner.prefix, @club.name)
    product_variant_stock_management_stubs_store
    click_link_or_button 'Import Data'      
    assert page.has_content?("Imported successfully data from Store for product") 
    assert page.has_content?("testing name")
    assert page.has_content?("TESTINGSKU")
    assert page.has_content?("15")
    assert page.has_content?("Yes")
    product = Product.first
    assert_equal product.name, 'testing name'
    assert_equal product.sku, 'TESTINGSKU'
    assert_equal product.stock, 15
    assert_equal product.allow_backorder, true
    assert_equal product.image_url, 'https://s3.amazonaws.com/sacdailydealsonmcdev/app/public/spree/products/74/product/favicon.jpg?1489696964'
    assert_equal product.weight, 3
    assert_equal product.store_id, 6
  end
end