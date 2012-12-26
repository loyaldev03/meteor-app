class RemoveRequestFromCommunication < ActiveRecord::Migration
  def up
  	remove_column :communications, :request
  end

  def down
  	add_column :communications, :request, :text
  end
end
