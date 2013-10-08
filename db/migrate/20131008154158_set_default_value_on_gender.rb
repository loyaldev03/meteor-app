class SetDefaultValueOnGender < ActiveRecord::Migration
  def up
    change_column :members, :gender, :string, :default => '', :limit => 1
  end

  def down
    change_column :members, :gender, :string, :default => nil, :limit => 1
  end
end
