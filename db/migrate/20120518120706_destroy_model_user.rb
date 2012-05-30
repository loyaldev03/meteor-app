class DestroyModelUser < ActiveRecord::Migration
  def up
    drop_table :users
  end
  def down
    create_table :users, {:id => false} do |t|
      t.string :uuid, :primary => true
      t.string :ip_address
      t.string :user_agent
      t.string :referer_host
      t.string :referer_path
      t.text :referer_params
      t.boolean :cookie_set
      t.integer :domain_id, :limit => 8
      t.timestamps
    end
  end

end
