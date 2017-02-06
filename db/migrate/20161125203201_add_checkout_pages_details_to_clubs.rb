class AddCheckoutPagesDetailsToClubs < ActiveRecord::Migration
  def change
    add_attachment :clubs, :favicon_url
    add_attachment :clubs, :header_image_url
    add_attachment :clubs, :result_pages_image_url
    add_column :clubs, :checkout_page_bonus_gift_box_content, :text
    add_column :clubs, :thank_you_page_content, :text
    add_column :clubs, :duplicated_page_content, :text
    add_column :clubs, :error_page_content, :text
    add_column :clubs, :checkout_page_footer, :text
    add_column :clubs, :result_page_footer, :text
  end
end
