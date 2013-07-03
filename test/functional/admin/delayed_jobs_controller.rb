require 'test_helper'

class Admin::DelayedJobsControllerTest < ActionController::TestCase

  test "agents that should get index" do
    [:confirmed_admin_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :index
      assert_response :success
    end
  end

  test "agents that sould not get index" do
    [:confirmed_supervisor_agent, :confirmed_representative_agent, 
     :confirmed_api_agent, :confirmed_fulfillment_manager_agent].each do |agent|
      @agent = FactoryGirl.create agent
      sign_in @agent
      get :index
      assert_response :unauthorized
    end
  end
end
