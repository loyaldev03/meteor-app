require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  test "should create product" do
    @product = FactoryGirl.build(:product)
    assert @product.save
  end

  test "should not save a product with package more than 19 digits" do
    assert_difference("Product.count",0) do
      @product = FactoryGirl.build(:product, :package => "aaaaaaaaaaaaaaaaaaaa")
      assert !@product.save, "Product was saved with package with more than 19 characters."
    end
  end

  test "should not save a product with cost center less than 2 digits" do
    assert_difference("Product.count",0) do
      @product = FactoryGirl.build(:product, :cost_center => "a")
      assert !@product.save, "Product was saved with package with less than 2 characters."
    end
  end

  test "should not save a product with cost center more than 30 digits" do
    assert_difference("Product.count",0) do
      @product = FactoryGirl.build(:product, :cost_center => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
      assert !@product.save, "Product was saved with package with more than 30 characters."
    end
  end

  test "Create a product with SKU more than 19 characters" do
    assert_difference("Product.count") do
      @product = FactoryGirl.build(:product, :sku => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
      assert @product.save
    end
  end

  test "Should not allow to update SKU if there are fulfillments related to it" do
    club = FactoryGirl.create(:club)
    user = FactoryGirl.create(:user, club_id: club.id )
    product = club.products.last
    FactoryGirl.create(:fulfillment, product_sku: product.sku, club_id: product.club_id, user_id: user.id, product_id: product.id)
    product.sku = "new_sku"
    assert !product.save
    assert product.errors.messages[:sku].include? "Cannot change this sku. There are fulfillments related to it."
  end

  test "Should not allow to delete product if there are fulfillments related to it" do
    club = FactoryGirl.create(:club)
    user = FactoryGirl.create(:user, club_id: club.id )
    product = club.products.last
    FactoryGirl.create(:fulfillment, product_sku: product.sku, club_id: product.club_id, user_id: user.id, product_id: product.id)
    assert !product.destroy
  end
end