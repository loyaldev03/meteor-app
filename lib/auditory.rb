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

  def self.report_issue(description = "", exception = nil, params = nil)
    unless ['test', 'development'].include? Rails.env
      Rollbar.error(exception, description, params)
    end
  end

  def self.create_user_story(description, title, project_id = Settings.pivotal_tracker.project_id, story_type = 'bug', assignee = nil)
    client = TrackerApi::Client.new(token: Settings.pivotal_tracker.token)
    project = client.project(project_id)
    story = project.create_story(name: "[#{Rails.env}] #{title}", story_type: story_type, description: description)
    story.attributes = { owner_ids: [assignee] } # Refer to config/initializers/pivotal_tracker.rb for a list of asignee ids.
    story.save
  end

  def self.notify_pivotal_tracker(error, exception = '', params = {}, assignee = nil)
    unless ['test', 'development'].include? Rails.env
      description = <<-EOF
        **Message:**
        ```#{exception}```

        -----------------------------

        **Parameters**
        \n#{params.collect{|k,v| "* #{k}: #{v}" }.join("\n")}

      EOF
      Auditory.create_user_story(description, error, Settings.pivotal_tracker.project_id, 'bug', assignee)
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

  def self.management_stock_notification(title, message, errors)
    unless ["test", "development"].include? Rails.env  
      description = <<-EOF
        **Message**
        ```#{message}```
        -------------------------------
        **Errors**
        \n#{errors.collect{|x| "* #{x}" }.join("\n")}
      EOF
      Auditory.create_user_story(description, title)
    end
  end

end
