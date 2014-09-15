class UserNote < ActiveRecord::Base
  attr_accessible :note_type, :description
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id', :with_deleted => true
  belongs_to :user
  belongs_to :disposition_type
  belongs_to :communication_type
  
  after_create :solr_index_asyn_call

	def solr_index_asyn_call
    self.user.asyn_solr_index if self.user
  end

end
