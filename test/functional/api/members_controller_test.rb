require 'test_helper'

class Api::MembersControllerTest < ActionController::TestCase

  test "should enroll/create member" do
    assert_difference('Member.count') do
      post :enrol, partner: { :prefix => @partner_prefix, :name => @partner.name, :contract_uri => @partner.contract_uri, :website_url => @partner.website_url, :description => @partner.description }
    end
  end
end
