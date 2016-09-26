module Clubs
  class ResyncUsersAndProspectsJob < ActiveJob::Base
    queue_as :generic_queue

    def perform(club_id:)
    club = Club.find(club_id)
    subscribers_count = club.members_count.to_i
      if subscribers_count > Settings.maximum_number_of_subscribers_to_automatically_resync
        Auditory.report_club_changed_marketing_client(club, subscribers_count)
      end
      club.users.update_all(need_sync_to_marketing_client: 1, marketing_client_synced_status: "not_synced", marketing_client_last_synced_at: nil, marketing_client_last_sync_error: nil, marketing_client_last_sync_error_at: nil, marketing_client_id: nil)
      club.prospects.update_all(need_sync_to_marketing_client: 1)
    end
  end
end