class AddAppleTouchIconToClubs < ActiveRecord::Migration
  def change
    add_attachment :clubs, :appletouch_icon_url
  end
end
