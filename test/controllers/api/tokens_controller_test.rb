require 'test_helper'

class Api::TokensControllerTest < ActionController::TestCase
  def setup
    @agent = FactoryBot.create(:agent)
  end


  test 'Request token for agent.' do
    post(:create, { email: @agent.email, password: @agent.password, format: :json } )
    assert_response :success
    assert_not_nil JSON.parse(@response.body)['token']
  end

  test 'Returns an error when requesting token for agent sending wrong email' do
    post(:create, { email: 'doesnotexists@xagax.com', password: @agent.password, format: :json } )
    assert_response :unauthorized
    assert_equal JSON.parse(@response.body)['message'], 'Invalid email or password.'
  end

  test 'Returns an error when requesting token for agent sending wrong password' do
    post(:create, { email: @agent.email, password: @agent.password + 'testing', format: :json } )
    assert_response :unauthorized
    assert_equal JSON.parse(@response.body)['message'], 'Invalid email or password.'
  end

  test 'Request token destroy' do
    @agent.generate_authentication_token
    original_token = @agent.authentication_token
    put(:destroy, { id: @agent.authentication_token, format: :json } )
    assert_response :success
    assert_not_equal @agent.reload.authentication_token, original_token
  end

  test 'Returns error when request token destroy sending wrong token' do
    @agent.generate_authentication_token
    original_token = @agent.authentication_token 
    put(:destroy, { id: @agent.authentication_token + 'testing', format: :json } )
    assert_response :not_found
    assert_equal @agent.reload.authentication_token, original_token
  end
end