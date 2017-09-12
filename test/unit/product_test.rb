require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  test "should create product" do
    @product = FactoryGirl.build(:product)
    assert @product.save
  end

  test "Do not allow to create a product with SKU more than 30 characters" do
    assert_difference("Product.count") do
      @product = FactoryGirl.build(:product, :sku => Faker::Lorem.characters(30))
      assert @product.save
      @product = FactoryGirl.build(:product, :sku => Faker::Lorem.characters(31))
      assert !@product.save
    end
  end

  test "Should allow to update SKU if there are fulfillments related to it" do
    club = FactoryGirl.create(:club)
    user = FactoryGirl.create(:user, club_id: club.id )
    product = club.products.last
    fulfillment = FactoryGirl.create(:fulfillment, product_sku: product.sku, club_id: product.club_id, user_id: user.id, product_id: product.id)
    product.sku = "NEW_SKU"
    assert product.save     
    product.reload
    fulfillment.reload     
    assert_equal(product.sku, "NEW_SKU")
    assert_equal(fulfillment.product_sku, "NEW_SKU")   
  end

  test "Should not allow to delete product if there are fulfillments related to it" do
    club = FactoryGirl.create(:club)
    user = FactoryGirl.create(:user, club_id: club.id )
    product = club.products.last
    FactoryGirl.create(:fulfillment, product_sku: product.sku, club_id: product.club_id, user_id: user.id, product_id: product.id)
    assert !product.destroy
  end

  test "Should not save 2 products with the same SKU in the same club" do
    product = FactoryGirl.create(:product, :sku => 'NCALENDARJIMMIEJOHNSON')
    product_same_sku = FactoryGirl.build(:product, :sku => product.sku)
    assert !product_same_sku.save
    assert product_same_sku.errors.messages[:sku].include? "has already been taken"
  end

  test "Should save 2 products with the same SKU in different clubs" do
    assert_difference("Product.count", 2) do
      club = FactoryGirl.create(:club_without_product)
      product = FactoryGirl.build(:product, :sku => 'NCALENDARJIMMIEJOHNSON', :club_id => club.id)
      assert product.save
      club1 = FactoryGirl.create(:club_without_product)
      product1 = FactoryGirl.build(:product, :sku => 'NCALENDARJIMMIEJOHNSON', :club_id => club1.id)
      assert product1.save
    end
  end
end