require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  test "should create product" do
    @product = FactoryBot.build(:product)
    assert @product.save
  end

  test "Do not allow to create a product with SKU more than 30 characters" do
    assert_difference("Product.count") do
      @product = FactoryBot.build(:product, :sku => Faker::Lorem.characters(30))
      assert @product.save
      @product = FactoryBot.build(:product, :sku => Faker::Lorem.characters(31))
      assert !@product.save
    end
  end

  test "Should allow to update SKU if there are fulfillments related to it" do
    club = FactoryBot.create(:club)
    user = FactoryBot.create(:user, club_id: club.id )
    product = club.products.last
    fulfillment = FactoryBot.create(:fulfillment, product_sku: product.sku, club_id: product.club_id, user_id: user.id, product_id: product.id)
    product.sku = "NEW_SKU"
    assert product.save     
    product.reload
    fulfillment.reload     
    assert_equal(product.sku, "NEW_SKU")
    assert_equal(fulfillment.product_sku, "NEW_SKU")   
  end

  test "Should not allow to delete product if there are fulfillments related to it" do
    club = FactoryBot.create(:club)
    user = FactoryBot.create(:user, club_id: club.id )
    product = club.products.last
    FactoryBot.create(:fulfillment, product_sku: product.sku, club_id: product.club_id, user_id: user.id, product_id: product.id)
    assert !product.destroy
  end

  test "Should not save 2 products with the same SKU in the same club" do
    product = FactoryBot.create(:product, :sku => 'NCALENDARJIMMIEJOHNSON')
    product_same_sku = FactoryBot.build(:product, :sku => product.sku)
    assert !product_same_sku.save
    assert product_same_sku.errors.messages[:sku].include? "has already been taken"
  end

  test "Should save 2 products with the same SKU in different clubs" do
    assert_difference("Product.count", 2) do
      club = FactoryBot.create(:club_without_product)
      product = FactoryBot.build(:product, :sku => 'NCALENDARJIMMIEJOHNSON', :club_id => club.id)
      assert product.save
      club1 = FactoryBot.create(:club_without_product)
      product1 = FactoryBot.build(:product, :sku => 'NCALENDARJIMMIEJOHNSON', :club_id => club1.id)
      assert product1.save
    end
  end
end