class ClubChangeDrupalTokenByUsernamePassword < ActiveRecord::Migration
  def up
    change_table :clubs do |t|
      t.remove :drupal_token
      t.string :drupal_username
      t.string :drupal_password
    end
  end

  def down
    change_table :clubs do |t|
      t.string :drupal_token
      t.remove :drupal_username
      t.remove :drupal_password
    end
  end
end
