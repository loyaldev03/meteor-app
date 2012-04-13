class CreateDomains < ActiveRecord::Migration
  def up
    create_table :domains, { :id => false } do |t|
      t.string :url
      t.text :description
      t.text :data_rights
      t.integer :partner_id, :limit => 8
      t.boolean :hosted
      t.datetime :deleted_at
      t.timestamps
    end
    execute "ALTER TABLE domains ADD COLUMN id BIGINT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY;" 
  end
  def down
    drop_table :domains
  end
end
