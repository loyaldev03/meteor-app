class CampaignDay < ActiveRecord::Base
  belongs_to :campaign

  scope :missing, -> {where('converted IS NULL OR spent IS NULL OR reached IS NULL')}
  scope :not_missing, -> { where.not(converted: nil, spent: nil, reached: nil) }

  enum meta: {
    no_error: 0,
    unauthorized: 1,
    invalid_campaign: 2,
    unexpected_error: 3
  }

  def is_missing?
    spent.nil? and reached.nil? and converted.nil?
  end

  def self.datatable_columns
    ['date', 'campaign', 'transport', 'spent', 'reached', 'converted']
  end
end