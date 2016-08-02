class CampaignDay < ActiveRecord::Base
  belongs_to :campaign

  def self.datatable_columns
    ['date', 'campaign', 'spent', 'reached', 'converted']
  end
end