require 'test_helper'

class AgentTest < ActiveSupport::TestCase
  setup do
    @agent = FactoryBot.build(:agent)
  end

  test 'Save agent when filling all data' do
    assert_difference('Agent.count') { assert @agent.save, "The agent #{@agent.email} was not created." }
  end

  test 'Should not create agent without username' do
    agent = FactoryBot.build(:agent, username: '')
    assert !agent.save
    assert agent.errors[:username].include? "can't be blank"
  end

  test 'Should not save agent without email' do
    @agent.email = nil
    assert !@agent.save, 'Agent was saved without email'
  end

  test 'Should not save agent without username' do
    @agent.username = nil
    assert !@agent.save, 'Agent was saved without username'
  end

  test 'Should not save agent without password' do
    @agent.password = nil
    assert !@agent.save, 'Agent was saved without password'
  end

  test 'Shouldnt be two users with same username' do
    first = FactoryBot.create(:agent, username: 'billy')
    assert first.valid?
    second = FactoryBot.build(:agent, username: 'billy')
    second.valid?
    assert_not_nil second.errors
  end

  test 'Should not save agent with different password and confirmation password' do
    @agent.password_confirmation = 'pepe'
    assert !@agent.save, 'Agent was saved with different password and confirmation password'
  end

  test 'Should not save two users with same email' do
    first = FactoryBot.create(:agent)
    assert first.valid?
    second = FactoryBot.build(:agent, email: first.email)
    second.valid?
    assert_not_nil second.errors
  end

  test 'Should not save an username with more than 20 characters' do
    user = FactoryBot.build(:agent, username: '123456789123456789123')
    assert !user.save, 'User was saved with a very long username'
  end
end
