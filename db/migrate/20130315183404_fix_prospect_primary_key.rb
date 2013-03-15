class FixProspectPrimaryKey < ActiveRecord::Migration
  def up
  	add_index "prospects", ["uuid"], :name => "index_prospects_on_uuid"
  end

  def down
  	remove_index "prospects", ["uuid"]
  end
end