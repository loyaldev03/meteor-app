require 'test_helper'

class PreferenceGroupTest < ActiveSupport::TestCase

  setup do    
    @preference_group = FactoryGirl.build(:preference_group)
  end

  test 'Should save preference group when saving all data' do
    assert !@preference_group.save, "The preference group #{@preference_group.name} was not created."
  end

  test 'Should not save preference group without name' do
    @preference_group.name = nil
    assert !@preference_group.save, "Preference group was saved without a name"
  end

  test 'Should not save preference group without code' do
    @preference_group.code = nil
    assert !@preference_group.save, "Preference group was saved without a code"
  end
end