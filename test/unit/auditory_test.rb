require 'test_helper'

class AuditoryTest < ActiveSupport::TestCase
  test 'save operation' do
    agent               = FactoryBot.create(:agent)
    club                = FactoryBot.create(:simple_club_with_gateway)
    terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway, club_id: club.id)
    user                = enroll_user(FactoryBot.build(:user), terms_of_membership)
    assert_difference('Operation.count') do
      assert Auditory.audit(agent, nil, 'test', user, Settings.operation_types.others)
    end
    operation = user.operations.last
    assert_equal operation.operation_type, Settings.operation_types.others
    assert_equal operation.description, 'test'
  end
end
