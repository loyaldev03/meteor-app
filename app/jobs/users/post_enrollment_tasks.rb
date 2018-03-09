module Users
  class PostEnrollmentTasks < ActiveJob::Base
    queue_as :fulfillments
    attr :user

    def testing_account_analysis
      mark_as_testing_account = false
      if ['name', 'firstname', 'test', 'sactest'].include? @user.first_name
        mark_as_testing_account = true
      elsif ['test', 'sactest', 'fctest', 'testing'].include? @user.last_name
        mark_as_testing_account = true
      elsif @user.email != 'guest@xagax.com' and ['xagax.com', 'stoneacreinc.com', 'meteoraffinity.com'].include? @user.email.split("@").last
        mark_as_testing_account = true
      end

      if mark_as_testing_account
        @user.update_attribute :testing_account, true
      end
    end

    def update_sumarize_data(fulfillment)
      Fulfillment.where(id: fulfillment.id).update_all("
        email_matches_count = (SELECT count(*) FROM suspected_fulfillment_evidences WHERE fulfillment_id = #{fulfillment.id} AND email_match = 1),
        full_name_matches_count = (SELECT count(*) FROM suspected_fulfillment_evidences WHERE fulfillment_id = #{fulfillment.id} AND full_name_match = 1),
        full_address_matches_count = (SELECT count(*) FROM suspected_fulfillment_evidences WHERE fulfillment_id = #{fulfillment.id} AND full_address_match = 1),
        full_phone_number_matches_count = (SELECT count(*) FROM suspected_fulfillment_evidences WHERE fulfillment_id = #{fulfillment.id} AND full_phone_number_match = 1),
        average_match_age = (SELECT AVG(match_age) FROM suspected_fulfillment_evidences WHERE fulfillment_id = #{fulfillment.id}),
        matching_fulfillments_count = (SELECT COUNT(*) FROM suspected_fulfillment_evidences WHERE fulfillment_id = #{fulfillment.id})
      ")
    end

    def proceed_with_gamer_analysis(fulfillment)
      suspected_of_gamer = false
      matched_fulfillments = Fulfillment.where("club_id = ? AND email = ? AND NOT id = ?", fulfillment.club_id, fulfillment.email, fulfillment.id)
      matched_fulfillments.each do |matched_fulfillment|
        evidence = SuspectedFulfillmentEvidence.where(fulfillment_id: fulfillment.id, matched_fulfillment_id: matched_fulfillment.id).first_or_create
        evidence.update_attribute :email_match, true
        suspected_of_gamer = true
      end

      matched_fulfillments = Fulfillment.where(
        "club_id = ? AND LCASE(REPLACE(full_address, ' ', '')) = ? AND NOT id = ?",
        fulfillment.club_id,
        fulfillment.full_address.downcase.gsub(/\s+/, ''),
        fulfillment.id
      )
      matched_fulfillments.each do |matched_fulfillment|
        evidence = SuspectedFulfillmentEvidence.where(fulfillment_id: fulfillment.id, matched_fulfillment_id: matched_fulfillment.id).first_or_create
        evidence.update_attribute :full_address_match, true
        suspected_of_gamer = true
      end

      matched_fulfillments = Fulfillment.where(
        "club_id = ? AND LCASE(REPLACE(full_name, ' ', '')) = ? AND NOT id = ? ",
        fulfillment.club_id,
        fulfillment.full_name.downcase.gsub(/\s+/, ''),
        fulfillment.id
      )
      matched_fulfillments.each do |matched_fulfillment|
        evidence = SuspectedFulfillmentEvidence.where(fulfillment_id: fulfillment.id, matched_fulfillment_id: matched_fulfillment.id).first_or_create
        evidence.update_attribute :full_name_match, true 
        suspected_of_gamer = true
      end

      allowed_phone_numbers = ['0, 000, 0000000']
      matched_fulfillments = Fulfillment.where(
        'club_id = ? AND full_phone_number NOT IN (?) AND full_phone_number = ? AND NOT id = ? AND full_phone_number IS NOT NULL',
        fulfillment.club_id,
        allowed_phone_numbers,
        fulfillment.full_phone_number,
        fulfillment.id
      )
      matched_fulfillments.each do |matched_fulfillment|
        evidence = SuspectedFulfillmentEvidence.where(fulfillment_id: fulfillment.id, matched_fulfillment_id: matched_fulfillment.id).first_or_create
        evidence.update_attribute :full_phone_number_match, true
        suspected_of_gamer = true
      end

      if suspected_of_gamer
        update_sumarize_data(fulfillment)
        fulfillment.set_as_manual_review_required
        Auditory.audit(nil, fulfillment, 'Assigned fulfillment upon enrollment.', fulfillment.user, Settings.operation_types.fulfillment_created_as_manual_review_required)
      else
        Auditory.audit(nil, fulfillment, 'Assigned fulfillment upon enrollment.', fulfillment.user, Settings.operation_types.fulfillment_created_as_not_processed)
      end
    end

    def send_fulfillment
      # we always send fulfillment to new members or members that do not have 
      # opened fulfillments (meaning that previous fulfillments expired).
      if @user.fulfillments.where_not_processed.empty?
        begin
          product = @user.current_membership.product
          fulfillment = Fulfillment.new product_sku: product.sku
          fulfillment.recurrent = product.recurrent 
          fulfillment.user_id = @user.id
          fulfillment.club_id = @user.club_id
          fulfillment.product = product
          fulfillment.save!
          if not @user.testing_account?
            fulfillment.store_fulfillment.notify_fulfillment_assignation if defined?(SacStore::FulfillmentModel) and fulfillment.store_fulfillment
            proceed_with_gamer_analysis(fulfillment)
          else
            fulfillment.set_as_canceled
          end

        rescue ActiveRecord::RecordInvalid => e
          Auditory.report_issue("Send Fulfillment", e, { user: @user.id, product: @user.current_membership.product_sku })
        end
      else
        message = "The user has already a not processed fulfillment and we cannot assign the requested fulfillment. Contact a Fulfillment Manager to decide what to do."
        Auditory.report_issue("Send Fulfillment", message, { user: @user.id, product: @user.current_membership.product_sku })
      end
    end

    def perform(user_id, skip_send_fulfillment)
      @user = User.find user_id

      testing_account_analysis
      send_fulfillment if not skip_send_fulfillment and @user.current_membership.product_id
      @user.after_save_sync_to_remote_domain unless @user.api_id
    end
  end
end