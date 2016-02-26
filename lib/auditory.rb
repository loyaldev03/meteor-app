class Auditory
  # current_agent : if null will find the "batch" agent used on scripts.
  # object : the object added/modify/deleted by agent
  # description : custom message 
  # user : user that must show this operation (only for operations that are related to users: e.g. CC management, Emails)
  # operation_type : operation type used by reporting/web to group operations
  # operation_date : date when the operation related was done. If this value is nil we save that operation with Time.zone.now
  def self.audit(current_agent, object, description, user = nil, operation_type = Settings.operation_types.others, operation_date = Time.zone.now, notes = nil)
    agent = current_agent || Agent.find_by(email: Settings.batch_agent_email)
    o = Operation.new :operation_date => operation_date, 
      :resource => object, :description => description, :operation_type => operation_type
    o.created_by = agent
    o.notes = notes
    if user
      o.user_id = user.id
      o.club_id = user.club_id
    elsif object.instance_of? Prospect
      o.club_id = object.club_id
    end
    o.save!
  rescue Exception => e
    Rails.logger.error " * * * * * CANT SAVE OPERATION #{e}"
  end

  def self.create_user_story(description, error)
    PivotalTracker::Client.token = Settings.pivotal_tracker.token
    project = PivotalTracker::Project.find(Settings.pivotal_tracker.project_id)
    project.stories.create(name: "[#{Rails.env}] #{error}", story_type: 'bug', description: description)
  end
  
  def self.report_issue(error = "Special Error", exception = '', params = {}, add_backtrace = true)
    unless ["test"].include? Rails.env  
      backtrace = add_backtrace ? "**Backtrace**\n #{(exception.kind_of?(Exception) ? exception.backtrace.join("\n").to_s : caller.join("\n").to_s)}" : ''
      description = <<-EOF
        **Message:**
        ```#{exception}```

        -----------------------------

        **Parameters**
        \n#{params.collect{|k,v| "* #{k}: #{v}" }.join("\n")}

        -----------------------------

        #{backtrace}
      EOF
      Auditory.create_user_story(description, error)
    end
  end

  def self.report_club_changed_marketing_client(club, subscribers_count)
    unless ["test", "development"].include? Rails.env  
      tasks = if club.exact_target_client?
       ['mkt_tools:sync_members_to_exact_target', 'mkt_tools:sync_prospects_to_exact_target']
      elsif club.mailchimp_mandrill_client?
        ['mkt_tools:sync_members_to_mailchimp', 'mkt_tools:sync_prospects_to_mailchimp']
      end
      description = <<-EOF
        Club #{club.id} - #{club.name} changed it's marketing client. We have to manually resync every member and prospect (total amount: #{subscribers_count}). 

        -----------------------------

        **Steps to follow**:
        * Step 1: Ask tech leader or Charly to disable the following tasks (comment lines where we invoke those taks within file 'rake_task_runner' in application root folder):
        * Step 2: Ask tech leader or Charly to run manually tasks that were commented in previous step. (Example: RAILS_ENV=production nohup rake mkt_tools:sync_prospects_to_exact_target) This task should be started before the end of the day, and it should be done before the night since every member/prospect will be synced and this task may affect other scripts

        -----------------------------

        **Tasks to run**:
        \n#{tasks.collect{|x| "* #{x}"}.join("\n")}
      EOF

      Auditory.create_user_story(description, "[IMMEDIATE] Club:marketing_client_changed")
    end
  end
end
