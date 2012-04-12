class CreatePartners < ActiveRecord::Migration
  def change
    create_table :partners do |t|
      t.string :prefix
      t.string :name
      t.string :contract_uri
      t.string :website_url
      t.text :description
      t.has_attached_file :logo
      t.datetime :deleted_at

      t.timestamps
    end
    execute "ALTER TABLE zzzz CHANGE id id BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT;"
  end
end
