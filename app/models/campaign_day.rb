class CampaignDay < ActiveRecord::Base
  belongs_to :campaign

  scope :missing, -> {where('converted IS NULL OR spent IS NULL OR reached IS NULL')}
  scope :not_missing, -> {where.not(converted: nil, spent: nil, reached: nil)}

  def self.datatable_columns
    ['date', 'campaign', 'spent', 'reached', 'converted']
  end
end