class AddCheckoutPagesDetailsToCampaigns < ActiveRecord::Migration
  def change
    add_attachment :campaigns, :header_image_url
    add_attachment :campaigns, :result_pages_image_url
    add_column :campaigns, :checkout_page_bonus_gift_box_content, :text, default: nil
    add_column :campaigns, :checkout_page_footer, :text, default: nil
    add_column :campaigns, :css_style, :text, default: nil
    add_column :campaigns, :duplicated_page_content, :text, default: nil
    add_column :campaigns, :error_page_content, :text, default: nil
    add_column :campaigns, :result_page_footer, :text, default: nil
    add_column :campaigns, :thank_you_page_content, :text, default: nil
  end
end