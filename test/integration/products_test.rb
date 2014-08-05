require 'test_helper'

class ProductsTest < ActionController::IntegrationTest

  setup do
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
    sign_in_as(@admin_agent)
  end

  def create_product(unsaved_product, validate = true)
		visit products_path(@partner.prefix, @club.name)
		click_link_or_button 'New Product'

		fill_in 'product[sku]', :with => unsaved_product.sku	
		fill_in 'product[name]', :with => unsaved_product.name
		fill_in 'product[stock]', :with => unsaved_product.stock
		fill_in 'product[weight]', :with => unsaved_product.weight
		fill_in 'product[package]', :with => unsaved_product.package
		fill_in 'product[cost_center]', :with => unsaved_product.cost_center
		check 'product[allow_backorder]' if unsaved_product.allow_backorder

		click_link_or_button 'Create Product'
		if validate
			assert page.has_content?("Product was successfully created")
			Product.find_by_sku(unsaved_product.sku)
  	end
  end

	test "product list" do
		unsaved_product = FactoryGirl.build(:product)
		saved_product = create_product unsaved_product
		visit products_path(@partner.prefix, @club.name)

		within("#products_table") do
	    	assert page.has_content?(saved_product.name)
	    	assert page.has_content?(saved_product.recurrent.to_s)
	   		assert page.has_content?(saved_product.stock.to_s)
			assert page.has_content?(saved_product.weight.to_s)
  		end
	end

	# Create a member with Allow backorder at false
	test "create, update, delete a product" do
		unsaved_product = FactoryGirl.build(:product, :allow_backorder => false)
		saved_product = create_product unsaved_product
		
		assert page.has_content?(saved_product.name)
		assert page.has_content?(saved_product.sku)
		assert page.has_content?(saved_product.stock.to_s)
		assert page.has_content?(saved_product.weight.to_s)

		click_link_or_button 'Edit'
		assert page.has_content?('Edit Product')

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
		assert page.has_content?("Product #{saved_product.sku} was successfully destroyed")

	end

	test "all links in product show must work" do
		unsaved_product = FactoryGirl.build(:product)
		saved_product = create_product unsaved_product

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

	test "Stock limit at Product" do
		unsaved_product = FactoryGirl.create(:product, :club_id => @club.id )
		visit products_path(@partner.prefix, @club.name)
		within("#products_table") do
			assert page.has_content?(unsaved_product.name)
			first(:link, 'Edit').click 
  	end

  	assert page.has_content?('Edit Product')
  	fill_in 'product[stock]', :with => '2000000'
  	click_link_or_button 'Update Product'
  	assert page.has_content?('must be less than 1999999')
	end

	test "Create empty product" do
		unsaved_product = FactoryGirl.create(:product, :club_id => @club.id )
		visit products_path(@partner.prefix, @club.name)

		click_link_or_button 'New Product'

  	click_link_or_button 'Create Product'
  	assert page.has_content?("can't be blank,is invalid")
  	assert page.has_content?("is not a number")
	end

	test "Create an invalid product" do
		unsaved_product = FactoryGirl.create(:product, :club_id => @club.id )
		visit products_path(@partner.prefix, @club.name)

		click_link_or_button 'New Product'
		fill_in 'product[sku]', :with => '@#$^&*&^%$#%^'
  	click_link_or_button 'Create Product'
  	assert page.has_content?("is invalid")
	end

	test "Create a product with negative stock" do
		unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :stock => -3 )
		create_product unsaved_product, false
  	assert page.has_content?("Stock cannot be negative. Enter positive stock, or allow backorder")
	end

	test "Duplicate product in the same club" do
		unsaved_product = FactoryGirl.create(:product, :club_id => @club.id )
		create_product unsaved_product, false
		assert page.has_content?("Product with sku '#{unsaved_product.sku}' already exists within this club.")
	end
	
	test "Create a product with package limit - 19 chars length" do
    	unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :package => "abcdefghijklmnopqrs" )
		create_product unsaved_product
	end

	test "Create a product with cost center limit - 30 chars length" do
        unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :cost_center => "abcdefghijklmnopqrstuvwxyzabcd" )
		create_product unsaved_product
	end

    test "Create a product with cost center more than 30 characters" do
        unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :cost_center => "abcdefghijklmnopqrstuvwxyzabcde" )		
        create_product unsaved_product, false
		assert page.has_content?("is too long (maximum is 30 characters)")
	end

 	test "Create a product with package more than 19 characters" do
        unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :package => "abcdefghijklmnopqrst" )
		create_product unsaved_product, false
		assert page.has_content?("is too long (maximum is 19 characters)")
	end

	test "Create a product with numbers at SKU " do
		unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :sku => "123456789" )
		create_product unsaved_product
	end
	
	test "Create a product with numbers at package " do
		unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :package => "123456789" )
		create_product unsaved_product, false
		assert page.has_content?("is invalid")
	end

	test "Create a member with Allow backorder at true" do
		unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :allow_backorder => true )
		create_product(unsaved_product)
	end
end