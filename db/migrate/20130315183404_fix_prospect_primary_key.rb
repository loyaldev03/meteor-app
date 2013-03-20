class FixProspectPrimaryKey < ActiveRecord::Migration
  def up
  	# add_index "prospects", ["uuid"], :name => "index_prospects_on_uuid2"
  end

  def down
  	# remove_index "prospects", :name => "index_prospects_on_uuid2"
  end
end
