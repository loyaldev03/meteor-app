class AsynElasticSearchIndexJob < ActiveJob::Base
  queue_as :elasticsearch_indexing

  def perform(user_id)
    user = User.find(user_id)
    user.index.store user
  end
end
