namespace :mkt_tools do

  desc "Sync members to pardot"
  # This task should be run each day at 3 am ?
  task :sync_members_to_pardot => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/mkt_tools_sync_members_to_pardot.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      if defined? Pardot::Member
        Member.sync_members_to_pardot
      end
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run mkt_tools:sync_members_to_pardot task"
    end
  end

  desc "Sync members to exact target"
  # This task should be run each day at 3 am ?
  task :sync_members_to_exact_target => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/mkt_tools_sync_members_to_exact_target.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      if defined? SacExactTarget::MemberModel
        Member.sync_members_to_exact_target
      end
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run mkt_tools:sync_members_to_exact_target task"
    end
  end

  desc "Sync prospects to exact target"
  # This task should be run each day at 3 am ?
  task :sync_prospects_to_exact_target => :environment do
    Rails.logger = Logger.new("#{Rails.root}/log/mkt_tools_sync_prospects_to_exact_target.log")
    Rails.logger.level = Logger::DEBUG
    ActiveRecord::Base.logger = Rails.logger
    tall = Time.zone.now
    begin
      if defined? SacExactTarget::ProspectModel
        Prospect.sync_prospects_to_exact_target
      end
    ensure
      Rails.logger.info "It all took #{Time.zone.now - tall} to run mkt_tools:sync_prospects_to_exact_target task"
    end
  end

end