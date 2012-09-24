require 'test_helper'

class ProductsTests < ActionController::IntegrationTest

  setup do
    init_test_setup
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club, :partner_id => @partner.id)
    sign_in_as(@admin_agent)
  end

	test "product list" do
		unsaved_product = FactoryGirl.build(:product)
		visit products_path(@partner.prefix, @club.name)

		click_link_or_button 'New Product'

		fill_in 'product[name]', :with => unsaved_product.name
		fill_in 'product[sku]', :with => unsaved_product.sku
		fill_in 'product[stock]', :with => unsaved_product.stock
		fill_in 'product[weight]', :with => unsaved_product.weight

   	click_link_or_button 'Create Product'
		visit products_path(@partner.prefix, @club.name)

		within("#products_table") do
			wait_until {
	      assert page.has_content?(unsaved_product.name)
	      assert page.has_content?(unsaved_product.recurrent.to_s)
	   		assert page.has_content?(unsaved_product.stock.to_s)
				assert page.has_content?(unsaved_product.weight.to_s)
	    }
  	end
	end


	test "create, update, delete a product" do
		unsaved_product = FactoryGirl.build(:product)
		visit products_path(@partner.prefix, @club.name)

		click_link_or_button 'New Product'

		fill_in 'product[name]', :with => unsaved_product.name
		fill_in 'product[sku]', :with => unsaved_product.sku
		fill_in 'product[stock]', :with => unsaved_product.stock
		fill_in 'product[weight]', :with => unsaved_product.weight

		assert_difference('Product.count') do
    	click_link_or_button 'Create Product'
    end
		
		assert page.has_content?("Product was successfully created")
		
		assert page.has_content?(unsaved_product.name)
		assert page.has_content?(unsaved_product.sku)
		assert page.has_content?(unsaved_product.stock.to_s)
		assert page.has_content?(unsaved_product.weight.to_s)

		click_link_or_button 'Edit'
		assert page.has_content?('Edit Product')

		saved_product = Product.find_by_name(unsaved_product.name)
		
		fill_in 'product[stock]', :with => saved_product.stock + 1
		fill_in 'product[weight]', :with => saved_product.weight + 1

		assert_difference('Product.count', 0) do
			click_link_or_button 'Update Product'
		end

		saved_product.reload
		
		assert page.has_content?("Product was successfully updated")

		assert page.has_content?(saved_product.stock.to_s)
		assert page.has_content?(saved_product.weight.to_s)

		confirm_ok_js

		assert_difference('Product.count', -1) do
			click_link_or_button 'Destroy'
		end

		assert page.has_content?("Product #{saved_product.name} was successfully destroyed")

	end

	test "all links in product show must work" do
		unsaved_product = FactoryGirl.build(:product)
		visit products_path(@partner.prefix, @club.name)

		click_link_or_button 'New Product'

		fill_in 'product[name]', :with => unsaved_product.name
		fill_in 'product[sku]', :with => unsaved_product.sku
		fill_in 'product[stock]', :with => unsaved_product.stock
		fill_in 'product[weight]', :with => unsaved_product.weight

		click_link_or_button 'Create Product'

		saved_product = Product.find_by_name(unsaved_product.name)

		click_link_or_button 'Edit'
		assert page.has_content?('Edit Product')
		
		click_link_or_button 'Cancel'
		assert page.has_content?('Search')
		visit product_path(@partner.prefix, @club.name, saved_product.id)
		
		click_link_or_button 'Back'
		assert page.has_content?('Search')
		visit product_path(@partner.prefix, @club.name, saved_product.id)
		confirm_ok_js
		click_link_or_button 'Destroy'
		assert page.has_content?('Search')		
	end

end