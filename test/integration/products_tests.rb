require 'test_helper'

class ProductsTests < ActionController::IntegrationTest

  setup do
    init_test_setup
    @admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @partner = FactoryGirl.create(:partner)
    @club = FactoryGirl.create(:simple_club_with_gateway, :partner_id => @partner.id)
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

	test "Stock limit at Product" do
		unsaved_product = FactoryGirl.create(:product, :club_id => @club.id )
		visit products_path(@partner.prefix, @club.name)
		within("#products_table") do
			wait_until { assert page.has_content?(unsaved_product.name) }
			click_link_or_button 'Edit'
  	end

  	wait_until{ assert page.has_content?('Edit Product') }
  	fill_in 'product[stock]', :with => '2000000'
  	click_link_or_button 'Update Product'
  	wait_until{ assert page.has_content?('must be less than 1999999') }
	end

	test "Create empty product" do
		unsaved_product = FactoryGirl.create(:product, :club_id => @club.id )
		visit products_path(@partner.prefix, @club.name)

		click_link_or_button 'New Product'

  	click_link_or_button 'Create Product'
  	wait_until{ assert page.has_content?("can't be blank,is invalid") }
  	wait_until{ assert page.has_content?("is not a number") }
	end

	test "Create an invalid product" do
		unsaved_product = FactoryGirl.create(:product, :club_id => @club.id )
		visit products_path(@partner.prefix, @club.name)

		click_link_or_button 'New Product'
		fill_in 'product[sku]', :with => '@#$^&*&^%$#%^'
  	click_link_or_button 'Create Product'
  	wait_until{ assert page.has_content?("is invalid") }
	end

	test "Create a product with negative stock" do
		unsaved_product = FactoryGirl.create(:product, :club_id => @club.id )
		visit products_path(@partner.prefix, @club.name)

		click_link_or_button 'New Product'
		fill_in 'product[stock]', :with => '-3'
  	click_link_or_button 'Create Product'
  	wait_until{ assert page.has_content?("must be greater than or equal to 0") }
	end

	test "Duplicate product in the same club" do
		unsaved_product = FactoryGirl.create(:product, :club_id => @club.id )
		visit products_path(@partner.prefix, @club.name)

		click_link_or_button 'New Product'
		fill_in 'product[sku]', :with => 'KIT'
  	click_link_or_button 'Create Product'
  	wait_until{ assert page.has_content?("has already been taken") }
	end
	
	test "Create a product with sku limit - 19 chars length" do
		unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :sku => "abcdefghijklmnopqrs" )
		visit products_path(@partner.prefix, @club.name)
		click_link_or_button 'New Product'

		wait_until{ 
			fill_in 'product[sku]', :with => unsaved_product.sku	
			fill_in 'product[name]', :with => unsaved_product.name
			fill_in 'product[stock]', :with => unsaved_product.stock
			fill_in 'product[weight]', :with => unsaved_product.weight
			fill_in 'product[package]', :with => unsaved_product.package
		}
		click_link_or_button 'Create Product'
		wait_until{ assert page.has_content?("Product was successfully created") }
	end

	test "Create a product with Package limit - 30 chars length" do
		unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :package => "abcdefghijklmnopqrstuvwxyzabcd" )
		visit products_path(@partner.prefix, @club.name)
		click_link_or_button 'New Product'

		wait_until{ 
			fill_in 'product[sku]', :with => unsaved_product.sku	
			fill_in 'product[name]', :with => unsaved_product.name
			fill_in 'product[stock]', :with => unsaved_product.stock
			fill_in 'product[weight]', :with => unsaved_product.weight
			fill_in 'product[package]', :with => unsaved_product.package
		}
		click_link_or_button 'Create Product'
		wait_until{ assert page.has_content?("Product was successfully created") }
	end

	test "Create a product with Package more than 30 characters" do
		unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :package => "abcdefghijklmnopqrstuvwxyzabcde" )
		visit products_path(@partner.prefix, @club.name)
		click_link_or_button 'New Product'

		wait_until{ 
			fill_in 'product[package]', :with => unsaved_product.package
		}
		click_link_or_button 'Create Product'
		wait_until{ assert page.has_content?("is too long (maximum is 30 characters)") }
	end

	test "Create a product with SKU more than 19 characters" do
		unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :sku => "abcdefghijklmnopqrst" )
		visit products_path(@partner.prefix, @club.name)
		click_link_or_button 'New Product'

		wait_until{ 
			fill_in 'product[sku]', :with => unsaved_product.sku
		}
		click_link_or_button 'Create Product'
		sleep 5
		wait_until{ assert page.has_content?("is too long (maximum is 19 characters)") }
	end

	test "Create a product with numbers at SKU " do
		unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :sku => "123456789" )
		visit products_path(@partner.prefix, @club.name)
		click_link_or_button 'New Product'

		wait_until{ 
			fill_in 'product[sku]', :with => unsaved_product.sku
		}
		click_link_or_button 'Create Product'
		wait_until{ assert page.has_content?("is invalid") }
	end
	
	test "Create a product with numbers at package " do
		unsaved_product = FactoryGirl.build(:product, :club_id => @club.id, :package => "123456789" )
		visit products_path(@partner.prefix, @club.name)
		click_link_or_button 'New Product'

		wait_until{ 
			fill_in 'product[package]', :with => unsaved_product.package
		}
		click_link_or_button 'Create Product'
		wait_until{ assert page.has_content?("is invalid") }
	end

end