require 'test_helper'

class TransportSettingTest < ActiveSupport::TestCase

  setup do
    @transportsetting = FactoryGirl.build(:transport_settings_facebook)
    @tsmailchimp = FactoryGirl.build(:transport_settings_mailchimp)
  end

  test 'Should save facebook transport settings when filling all data' do
    assert !@transportsetting.save, "The transport setting #{@transportsetting.transport} was not created."
  end

  test 'Should not save transport settings without transport' do
    @transportsetting.transport = nil
    assert !@transportsetting.save, "Transport settings was saved without transport"
  end

  test 'Should not save transport settings without client_id' do
    @transportsetting.client_id = nil
    assert !@transportsetting.save, "Transport settings was saved without client_id"
  end

  test 'Should not save transport settings without client_secret' do
    @transportsetting.client_secret = nil
    assert !@transportsetting.save, "Transport settings was saved without client_secret"
  end

  test 'Should not save transport settings without access_token' do
    @transportsetting.access_token = nil
    assert !@transportsetting.save, "Transport settings was saved without access_token"
  end

  test 'Should save mailchimp transport settings when filling all data' do
    assert !@tsmailchimp.save, "The transport setting #{@tsmailchimp.transport} was not created."
  end

  test 'Should not save transport settings without api_key' do    
    @tsmailchimp.api_key = nil
    assert !@tsmailchimp.save, "Transport settings was saved without api_key"
  end

  test 'Should not create more than 1 transport for the same club' do
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @transportsetting1 = FactoryGirl.create(:transport_settings_facebook, :club_id => @club.id)
    @transportsetting2 = FactoryGirl.build(:transport_settings_facebook, :club_id => @club.id)
    assert !@transportsetting2.save        
    assert @transportsetting2.errors.messages[:transport].include? "has already been taken"   
  end
end