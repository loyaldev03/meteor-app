class CampaignNotifier < ActionMailer::Base
  default from: Settings.platform_email
  default bcc: Settings.platform_admins_email
  layout 'mailer'

  def missing_campaign_days(club_id:, data:)
    @club = Club.find club_id
    @data = data
    mail to: Settings.campaign_manager_recipients, subject: I18n.t('mailers.missing_campaign_days.subject', club_name: @club.name)
  end

  def invalid_credentials(club_id:, campaign_ids:)
    @club = Club.find club_id
    @data = Campaign.where(id: campaign_ids).group_by{ |campaign| campaign.transport }
    mail to: Settings.campaign_manager_recipients, subject: I18n.t('mailers.invalid_credentials_email.subject', club_name: @club.name)
  end

  def invalid_campaign(campaign_ids:)
    @campaigns = Campaign.where(id: campaign_ids)
    mail to: Settings.campaign_manager_recipients, subject: I18n.t('mailers.invalid_campaign_email.subject')
  end

  def campaign_all_days_fetcher_result(campaign_id:)
    @campaign         = Campaign.find(campaign_id)
    @days_with_error  = @campaign.campaign_days.where.not(meta: CampaignDay.meta[:no_error])
    mail to: Settings.campaign_manager_recipients, subject: I18n.t('mailers.campaign_all_days_fetcher_result.subject', campaign_name: @campaign.name)
  end

end