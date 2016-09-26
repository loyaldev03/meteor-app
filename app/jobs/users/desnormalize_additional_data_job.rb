module Users
  class DesnormalizeAdditionalDataJob < ActiveJob::Base
    queue_as :generic_queue
    
    def perform(user_id:)
      user = User.find user_id
      if user.additional_data.present?
        user.additional_data.each do |key, value|
          pref = UserAdditionalData.where(user_id: user.id, club_id: user.club_id, param: key).first_or_create
          pref.value = value
          pref.save
        end
      end
    end
  end
end