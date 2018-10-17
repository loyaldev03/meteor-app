class RenameCampaignsAttachmentColumns < ActiveRecord::Migration
  def change
    change_table :campaigns do |t|
      t.rename :header_image_url_content_type, :header_image_content_type
      t.rename :header_image_url_file_name, :header_image_file_name
      t.rename :header_image_url_file_size, :header_image_file_size
      t.rename :header_image_url_updated_at, :header_image_updated_at

      t.rename :favicon_url_content_type, :favicon_content_type
      t.rename :favicon_url_file_name, :favicon_file_name
      t.rename :favicon_url_file_size, :favicon_file_size
      t.rename :favicon_url_updated_at, :favicon_updated_at

      t.rename :result_pages_image_url_content_type, :result_pages_image_content_type
      t.rename :result_pages_image_url_file_name, :result_pages_image_file_name
      t.rename :result_pages_image_url_file_size, :result_pages_image_file_size
      t.rename :result_pages_image_url_updated_at, :result_pages_image_updated_at
    end
  end
end
