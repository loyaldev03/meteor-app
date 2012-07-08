class ThemeSwitcherForClub < ActiveRecord::Migration
  def change
    add_column :clubs, :theme, :string, :default => 'application'
  end
end
