class AddJointToProspect < ActiveRecord::Migration
  def change
    add_column :prospects, :joint, :boolean, :default => true
  end
end
