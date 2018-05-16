module Users
  class SyncToRemoteDomainJob < ActiveJob::Base
    queue_as :generic_queue

    def perform(user_id:, tries: 0)
      begin
        user = User.find(user_id)
        user.api_user.save! if user.api_user
      rescue Exception => e
        if e.to_s.include? "ReadTimeout" and tries < 5
          Users::SyncToRemoteDomainJob.set(wait: 10.minutes).perform_later(user_id: user_id, tries: tries + 1)
        else
          Auditory.report_issue("SyncToRemoteDomain::drupal_sync", e, { user: user.id })
        end
      end
    end
  end
end