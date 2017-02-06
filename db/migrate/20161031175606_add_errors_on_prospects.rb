class AddErrorsOnProspects < ActiveRecord::Migration
  def change
    add_column :prospects, :error_messages, :text
  end
end
