namespace :billing do
  desc "Find members that have NBD for today. and bill them all!"
  # This task should be run each day at 3 am ?
  task :for_today => :environment do
    Member.find_in_batches(:conditions => [" next_retry_bill_date = ? ", Date.today]) do |group|
      group.each do |member| 
        member.bill_membership
      end
      sleep(5) # Make sure it doesn't get too crowded in there!
    end
  end

  desc "Send prebill emails"
  # This task should be run each day at 3 am ?
  task :for_today => :environment do
    Member.find_in_batches(:conditions => [" bill_date = ? ", Date.today = 7.days ]) do |group|
      group.each do |member| 
        member.send_pre_bill
      end
      sleep(5) # Make sure it doesn't get too crowded in there!
    end
  end
end
