require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase

  setup do    
    @preference = FactoryBot.build(:preference)
  end

  test 'Should save preference when saving all data' do
    assert !@preference.save, "The preference #{@preference.name} was not created."
  end

  test 'Should not save preference without name' do
    @preference.name = nil
    assert !@preference.save, "Preference was saved without a name"
  end
end