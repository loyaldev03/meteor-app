class ChangeColumnNameOnProspects < ActiveRecord::Migration
  def up
  	rename_column :prospects, :url_landing, :landing_url
  end

  def down
  	rename_column :prospects, :landing_url, :url_landing
  end
end
