class ClubRole < ActiveRecord::Base
  belongs_to :club
  belongs_to :agent, touch: true

  validates :club_id, 
    presence: true
  validates :agent_id,
    presence: true
  validates :role,
    presence: true,
    uniqueness: { scope: [:agent_id, :club_id] }

  attr_accessible :role, :club_id
end