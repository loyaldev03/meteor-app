class AddDrupalDomainAndTokenToClub < ActiveRecord::Migration
  def change
    change_table :clubs do |t|
      t.integer :drupal_domain_id
      t.string :drupal_token
    end
  end
end
