module Users
  class DesnormalizePreferencesJob < ActiveJob::Base
    queue_as :generic_queue
    
    def perform(user_id:)
      user = User.find user_id
      if user.preferences.present?
        user.preferences.each do |key, value|
          pref = UserPreference.find_or_create_by(user_id: user.id, club_id: user.club_id, param: key)
          pref.value = value
          pref.save
        end
      end
    end
  end
end