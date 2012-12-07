class Notifier < ActionMailer::Base
  default from: "platform@xagax.com"
  default bcc: "platformadmins@xagax.com"
  

  def active_with_approval(agent,member)
    @agent = agent
    @member = member
    mail :to => agent.email, :subject => "Member activation needs approval"
  end

  def recover_with_approval(agent,member)
    @agent = agent
    @member = member
    mail :to => agent.email, :subject => "Member recovering needs approval"
  end

  def call_these_members(csv)
    attachments["call_members_#{Date.today}.csv"] = { :mime_type => 'text/csv', :content => csv }
    mail :to => Settings.call_these_members_recipients, 
         :subject => "AUS answered CALL to these members #{Date.today}",
         :bcc => 'platformadmins@xagax.com'
  end

  def members_with_duplicated_email_sync_error(member_list)
    @members = member_list
    mail :to => Settings.call_these_members_recipients,
         :bcc => agent_email_list,         
         :subject => "Members with duplicated email sync error"
  end
end
