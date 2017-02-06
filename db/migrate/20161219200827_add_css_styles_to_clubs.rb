class AddCssStylesToClubs < ActiveRecord::Migration
  def change
    add_column :clubs, :css_style, :text
  end
end
