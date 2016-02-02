class SendFulfillmentJob < ActiveJob::Base
  queue_as :fulfillments

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
    matched_fulfillments = Fulfillment.where("club_id = ? AND assigned_at > ? AND email = ? AND NOT id = ?", fulfillment.club_id, 1.year.ago, fulfillment.email, fulfillment.id)
    matched_fulfillments.each do |matched_fulfillment|
      evidence = SuspectedFulfillmentEvidence.where(fulfillment_id: fulfillment.id, matched_fulfillment_id: matched_fulfillment.id).first_or_create
      evidence.update_attribute :email_match, true
      suspected_of_gamer = true
    end

    matched_fulfillments = Fulfillment.where("club_id = ? AND assigned_at > ? AND full_address = ? AND NOT id = ?", fulfillment.club_id, 1.year.ago, fulfillment.full_address, fulfillment.id)
    matched_fulfillments.each do |matched_fulfillment|
      evidence = SuspectedFulfillmentEvidence.where(fulfillment_id: fulfillment.id, matched_fulfillment_id: matched_fulfillment.id).first_or_create
      evidence.update_attribute :full_address_match, true
      suspected_of_gamer = true
    end

    matched_fulfillments = Fulfillment.where("club_id = ? AND assigned_at > ? AND full_name = ? AND NOT id = ? ", fulfillment.club_id, 1.year.ago, fulfillment.full_name, fulfillment.id)
    matched_fulfillments.each do |matched_fulfillment|
      evidence = SuspectedFulfillmentEvidence.where(fulfillment_id: fulfillment.id, matched_fulfillment_id: matched_fulfillment.id).first_or_create
      evidence.update_attribute :full_name_match, true 
      suspected_of_gamer = true
    end

    matched_fulfillments = Fulfillment.where("club_id = ? AND assigned_at > ? AND full_phone_number = ? AND NOT id = ? AND full_phone_number IS NOT NULL", fulfillment.club_id, 1.year.ago, fulfillment.full_phone_number, fulfillment.id)
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

  def perform(user_id)
    # we always send fulfillment to new members or members that do not have 
    # opened fulfillments (meaning that previous fulfillments expired).
    user = User.find user_id
    if user.fulfillments.where_not_processed.empty?
      begin
        product = user.product_to_send
        fulfillment = Fulfillment.new product_sku: product.sku
        fulfillment.product_package = product.package
        fulfillment.recurrent = product.recurrent 
        fulfillment.user_id = user.id
        fulfillment.club_id = user.club_id
        fulfillment.product = product
        fulfillment.save!
        proceed_with_gamer_analysis(fulfillment)
      rescue ActiveRecord::RecordInvalid => e
        Auditory.report_issue("Send Fulfillment", e, { user: user.id, product: user.product_to_send.sku })
      end
    else
      message = "The user has already a not processed fulfillment and we cannot assign the requested fulfillment. Contact a Fulfillment Manager to decide what to do."
      Auditory.report_issue("Send Fulfillment", message, { user: user.id, product: user.product_to_send.sku })
    end
  end
end
  
