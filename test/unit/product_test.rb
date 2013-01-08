require 'test_helper'

class ProductTest < ActiveSupport::TestCase

	test "should create product" do
			@product = FactoryGirl.build(:product)
			assert @product.save
	end

	test "should not save a product with sku less than 2 digits" do
		assert_difference("Product.count",0)do
			@product = FactoryGirl.build(:product, :sku => "a")
			assert !@product.save, "Product was saved with sku with less than 2 characters."
		end
	end

	test "should not save a product with sku more than 19 digits" do
		assert_difference("Product.count",0)do
			@product = FactoryGirl.build(:product, :sku => "aaaaaaaaaaaaaaaaaaaa")
			assert !@product.save, "Product was saved with sku with more than 19 characters."
		end
	end

	test "should not save a product with package less than 2 digits" do
		assert_difference("Product.count",0)do
			@product = FactoryGirl.build(:product, :package => "a")
			assert !@product.save, "Product was saved with package with less than 2 characters."
		end
	end

	test "should not save a product with package less than 30 digits" do
		assert_difference("Product.count",0)do
			@product = FactoryGirl.build(:product, :package => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
			assert !@product.save, "Product was saved with package with more than 30 characters."
		end
	end
end