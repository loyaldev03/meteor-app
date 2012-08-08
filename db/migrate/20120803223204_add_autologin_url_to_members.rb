class AddAutologinUrlToMembers < ActiveRecord::Migration
  def change
  	change_table :members do |t|
  	  t.text :autologin_url
  	end
  end
end
