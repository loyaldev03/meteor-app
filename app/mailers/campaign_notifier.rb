class CampaignNotifier < ActionMailer::Base
  default from: Settings.platform_email
  default bcc: Settings.platform_admins_email
  layout 'mailer'

  def missing_campaign_days(club_id:, data:)
    @club = Club.find club_id
    @data = data
    mail(to: Settings.campaign_manager_recipients, subject: I18n.t('mailers.missing_campaign_days.subject'))
  end

  def invalid_credentials(club_id:, campaign_ids:)
    @club = Club.find club_id
    @data = Campaign.where(id: campaign_ids).group_by{ |campaign| campaign.transport }
    mail to: Settings.campaign_manager_recipients, subject: I18n.t('mailers.invalid_credentials_email.subject')
  end

  def invalid_campaign(campaign_ids:)
    @campaigns = Campaign.where(id: campaign_ids)
    mail to: Settings.campaign_manager_recipients, subject: I18n.t('mailers.invalid_campaign_email.subject')
  end

end