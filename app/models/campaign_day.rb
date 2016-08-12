class CampaignDay < ActiveRecord::Base
  belongs_to :campaign

  scope :not_missing, -> { where.not(converted: nil, spent: nil, reached: nil) }

  enum meta: {
    no_error: 0,
    unauthorized: 1,
    invalid_campaign: 2
  }

  scope :missing, -> {where('converted IS NULL OR spent IS NULL OR reached IS NULL')}

  def self.datatable_columns
    ['date', 'campaign', 'spent', 'reached', 'converted']
  end
end