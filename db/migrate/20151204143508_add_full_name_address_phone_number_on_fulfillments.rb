class AddFullNameAddressPhoneNumberOnFulfillments < ActiveRecord::Migration
  def change
    add_column :fulfillments, :full_name, :string
    add_column :fulfillments, :full_address, :string
    add_column :fulfillments, :full_phone_number, :string
  end
end
