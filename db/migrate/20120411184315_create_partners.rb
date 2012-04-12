class CreatePartners < ActiveRecord::Migration
  def up
    create_table :partners, { :id => false } do |t|
      t.integer :id, :limit => 8
      t.string :prefix
      t.string :name
      t.string :contract_uri
      t.string :website_url
      t.text :description
      t.has_attached_file :logo
      t.datetime :deleted_at
      t.timestamps
    end
    execute "ALTER TABLE partners ADD PRIMARY KEY (id);" 
  end
  def down
    drop_table :partners
  end
end
