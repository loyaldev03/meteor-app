dclass CreateUsers < ActiveRecord::Migration
  def up
    create_table :users, {:id => false} do |t|
      t.string :id, :primary => true
      t.string :ip_address
      t.string :user_agent
      t.string :referer_host
      t.string :referer_path
      t.text :referer_params
      t.boolean :cookie_set
      t.integer :domain, :limit => 8
      t.timestamps
    end
  end
  def down
    drop_table :users
  end
end
