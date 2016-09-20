class AddIndexOnTermsOfMembershipIdOnCampaignsTable < ActiveRecord::Migration
  def change
    add_index :campaigns, :terms_of_membership_id
  end
end
