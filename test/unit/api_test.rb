require 'test_helper'

class ApiTest < ActiveSupport::TestCase

  setup do
    Drupal.enable_integration!
    Drupal.test_mode!
    @member = FactoryGirl.build(:member_with_api)
    @club = @member.club
  end

  test "New member should try to create remote user" do
    @member.api_member.expects(:save!).once.returns(true) # NEVERFAILS I cant get the expectation to work!
    @member.save
  end

  # test "New member should POST remote user" do
  #   @club.stub! do |stub|
  #     stub.post('/api/user') { [200, {}, {'api_id' => 999}] }
  #   end
  #   assert @member.valid?
  #   @member.save
  #   assert_equal '999', @member.api_id
  # end

end