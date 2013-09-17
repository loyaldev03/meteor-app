class AddSourceToProspectAndEnrollmentInfo < ActiveRecord::Migration
  def up
  	add_column :enrollment_infos, :source, :string
  	add_column :prospects, :source, :string
  end

  def down
  	remove_column :enrollment_infos, :source
  	remove_column :prospects, :source
  end

end
