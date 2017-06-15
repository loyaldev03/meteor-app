class AddShowInSaveTheSaleToTermsOfMemberships < ActiveRecord::Migration
  def change
    add_column :terms_of_memberships, :show_in_save_the_sale, :boolean, default: false
  end
end
