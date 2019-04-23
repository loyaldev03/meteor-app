class CommunicationTest < ActiveSupport::TestCase
  setup do
    @club     = FactoryBot.create(:simple_club_with_gateway)
    @partner  = @club.partner
    Time.zone = @club.time_zone
    @terms_of_membership = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
  end

  test 'If club does not have billing enable we should not send any communication.' do
    saved_user = create_active_user(@terms_of_membership)
    saved_user.club.update_attribute :billing_enable, false
    saved_user.reload
    EmailTemplate::TEMPLATE_TYPES.each do |type|
      assert_difference('Operation.count', 0) do
        assert_difference('Communication.count', 0) do
          Communication.deliver!(type, saved_user)
        end
      end
    end
  end

  test "If user's email contains '@noemail.com' it should not send emails." do
    user = enroll_user(FactoryBot.build(:user, email: 'testing@noemail.com'), @terms_of_membership)
    assert_difference('Operation.count', 1) do
      Communication.deliver!(:active, user)
      assert_equal user.reload.operations.last.description, "The email contains '@noemail.com' which is an empty email. The email won't be sent."
    end
  end
end
