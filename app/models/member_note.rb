class MemberNote < ActiveRecord::Base
  attr_accessible :note_type, :description
  belongs_to :created_by, :class_name => 'Agent', :foreign_key => 'created_by_id', :with_deleted => true
  belongs_to :member
  belongs_to :disposition_type
  belongs_to :communication_type
  
  after_create :solr_index_asyn_call

	def solr_index_asyn_call
    self.member.asyn_solr_index if self.member
  end

end
