module Campaigns::CheckoutsHelper
  def replace_tokens(text, club, campaign = nil, prospect = nil)
    return '' if text.nil?
    [
      ['%%DELIVERY_DATE%%',         campaign.present? ? campaign.delivery_date : ''],
      ['%%CLUB_NAME%%',             club.name],
      ['%%ENROLLMENT_AMOUNT%%',     campaign.present? ? number_to_currency(campaign.enrollment_price) : ''],
      ['%%MEMBERSHIP_AMOUNT%%',     campaign.present? ? number_to_currency(campaign.terms_of_membership.installment_amount) : ''],
      ['%%TRIAL_PERIOD%%',          campaign.present? ? campaign.terms_of_membership.provisional_days.to_s + ' day(s)' : ''],
      ['%%CS_EMAIL%%',              club.cs_email],
      ['%%CS_PHONE_NUMBER%%',       club.cs_phone_number],
      ['%%PRIVACY_POLICY_URL%%',    club.privacy_policy_url],
      ['%%TWITTER_URL%%',           club.twitter_url],
      ['%%FACEBOOK_URL%%',          club.facebook_url],
      ['%%LANDING_URL%%',           campaign.present? ? campaign.landing_url : ''],
      ['%%CHECKOUT_URL%%',          (campaign.present? && prospect.present?) ? new_checkout_url(campaign_id: campaign, token: prospect.token) : '']
    ].each do |pair|
      text.gsub! pair[0], (!pair[1].nil? ? pair[1] : '')
    end
    text
  end

  def format_phone_number(prospect)
    return '' if prospect.nil?
    "(#{prospect.phone_area_code.to_s}) #{prospect.phone_local_number.to_s[0..2]}-#{prospect.phone_local_number.to_s[3..6]}"
  end
end
