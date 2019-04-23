require 'test_helper'

class DispositionTypeTest < ActiveSupport::TestCase
  def setup
    @club = FactoryBot.create(:simple_club_with_gateway)
  end

  test 'Should not save disposition type with duplicated name within same club' do
    created_disposition_type    = @club.disposition_types.first
    duplicated_disposition_type = FactoryBot.build(:disposition_type, name: created_disposition_type.name, club_id: @club.id)
    assert !duplicated_disposition_type.save
    assert duplicated_disposition_type.errors[:name].include? 'has already been taken'
  end
end
