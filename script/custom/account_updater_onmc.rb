require 'config/environment.rb'
require 'faraday'

## ONMC version

@password = 'do3!lAjo5'
@merchant = '941000110028'
@username = '941000110028AUS'
@url = 'https://www.merchante-solutions.com/'
@folder = "#{RAILS_ROOT rescue Rails.root}/mes_account_updater_files"

ActionMailer::Base.smtp_settings = {
  :enable_starttls_auto => true,
  :address        => 'smtp.gmail.com',
  :port           => 587,
  :domain         => 'xagax.com',
  :authentication => :login,
  :user_name      => 'platform@xagax.com',
  :password       => 'a4my0fm3'
}

class Notifier < ActionMailer::Base
  def call_these_members(csv)
    subject    "AUS answered CALL to these members #{Date.today}"
    bcc        'platformadmins@xagax.com'
    recipients 'jelwood@stoneacreinc.com,jsmith@stoneacreinc.com'
    from       'platform@xagax.com'
    attachment :content_type => "text/csv", :filename => "call_members_#{Date.today}.csv" do |a|
      a.body = csv
    end
  end
end


def store_file
  ################################################
  ########## new file!
  ################################################
  local_filename = "#{@folder}/onmc_account_updater_#{Time.zone.now}.txt"
  file = File.open(local_filename, 'w')

  # add header
  record_type, version_id, merchant_id = 'H1', '100000', "%-32s" % @merchant
  file.write [ record_type, version_id, merchant_id ].join + "\n"

  count = 0
  # members with expired credit card and active
  members = Member.find(:all, :select => "DISTINCT(encrypted_cc_number), members.*",
      :conditions => [ 'cs_next_bill_date = ? and renewable = 1 and (trial = 1 or active = 1) ' + 
          ' AND (aus_sent_at IS NULL OR (aus_sent_at < ? AND aus_status IS NULL) ) AND is_prospect != 1', 
          (Time.zone.now+7.days).to_date, (Time.zone.now-1.days).to_date ])
  members.each do |member|
    
    ActiveMerchant::Billing::CreditCard.require_verification_value = false
    credit_card = ActiveMerchant::Billing::CreditCard.new(
      :number     => member.cc_number,
      :month      => member.cc_month_exp,
      :year       => member.cc_year_exp,
      :first_name => member.first_name,
      :last_name  => member.last_name
    )
    credit_card.valid?
    account_type = case credit_card.type
    when 'visa'
      'VISA'
    when 'master'
      'MC  '
    else
      puts credit_card.type
      nil
    end
    # only master and visa allowed
    next if account_type.nil?

    member.aus_sent_at = Time.zone.now
    member.save

    # add cc line
    record_type, account_number, expiration_date, descretionary_data = 'D1', "%-32s" % member.cc_number.strip.gsub(' ', ''), 
      member.cc_year_exp.to_s[2..3]+("%02d" % member.cc_month_exp), "M%-31s"% member.id

    file.write [ record_type, account_type, account_number, expiration_date, descretionary_data ].join + "\n"
    count += 1
  end

  # add trailer
  record_type, record_count = 'T1', "%06d" % count
  file.write [ record_type, record_count ].join
  file.close
  ################################################
  ########## new file!
  ################################################

  local_filename
end

def send_file_to_mes(local_filename)
  if local_filename.nil?
    puts "Filename must be valid" 
    exit
  end

  conn = Faraday.new(:url => @url, :ssl => {:verify => false}) do |builder|
    builder.request :multipart
    builder.adapter  Faraday.default_adapter  # make requests with Net::HTTP  
  end

  payload = {}
  payload[:file] = Faraday::UploadIO.new(local_filename, 'multipart/form-data')
  payload[:userId] = @username
  payload[:userPass] = @password
  payload[:merchId] = @merchant 

  result = conn.post '/srv/api/ausUpload', payload
  answer = Rack::Utils.parse_nested_query(result.body)

  log answer.inspect
end

def request_file_by_id(file_id, filename)
  conn = Faraday.new(:url => @url, :ssl => {:verify => false})
  result = conn.get '/srv/api/ausDownload?', { 
    :userId => @username, 
    :userPass => @password, 
    :merchId => @merchant, 
    :rspfId => file_id
  }    
  answer = Rack::Utils.parse_nested_query(result.body)
  log answer.inspect

  if answer['rspCode'].to_i == 0
    full_filename = "#{@folder}/#{filename}"
    file = File.open(full_filename, 'w')
    file.write answer
    file.close
    parse_file full_filename
  end
end

def parse_file(filename)
  ids = []
  File.open(filename).each do |line|
    # do not parse header or trailers.
    next if line[0..0] == 'H' or line[0..0] == 'T'
    # TODO: IMPROVEMENT: we can add a flag on each credit card to know if it was or nor processed
    record_type = line[0..1]
    old_account_type = line[2..5]
    old_account_number = line[6..37].strip
    old_expiration_date = line[38..41]
    new_account_type = line[42..45]
    new_account_number = line[46..77].strip
    new_expiration_date = line[78..81]
    response_code = line[82..89].strip
    response_source = line[90..91]
    discretionary_data = line[92..123]

    [ record_type, old_account_type , old_account_number, old_expiration_date, new_account_type, new_account_number, new_expiration_date, response_code, response_source, discretionary_data ].each do |f|
      puts "-#{f}-"
    end

    members = Member.find_all_by_encrypted_cc_number Member.new(:cc_number => old_account_number).encrypted_cc_number
    if members.size > 4
      log "There are more than 4 members with the same CC number. Afraid of update all of them???"
    else
      members.each do |member|
        update_member member, response_code, new_account_number, new_expiration_date, line
      end
    end

    #member = Member.find discretionary_data[1..32].strip
    #if member.nil?
    #  log "Member id not found ##{discretionary_data} while parsing. #{line}"
    #else
    #  update_member member, response_code, new_account_number, new_expiration_date
    #end

    ids << discretionary_data[1..32].strip if response_code == "CALL"
  end

  send_email_with_call_members(ids)
end

def send_email_with_call_members(ids)
  unless ids.empty?
    members = Member.find(ids)
    csv = "id,first_name,last_name,trial,active,cs_next_bill_date\n"
    csv += members.collect {|m| [ m.id, m.first_name, m.last_name, m.trial, m.active, m.cs_next_bill_date ].join(',') }.join("\n")
    Notifier.deliver_call_these_members(csv)
  end
end

def update_member(member, response_code, new_account_number, new_expiration_date, line)
  member.aus_answered_at = Time.zone.now
  member.aus_status = response_code
  update_cs = false
  case response_code
  when 'NEWACCT'
    update_cs = true
    member.cc_number = new_account_number
    member.cc_year_exp = new_expiration_date[0..1].to_i+2000
    member.cc_month_exp = new_expiration_date[2..3]
  when 'NEWEXP'
    update_cs = true
    member.cc_year_exp = new_expiration_date[0..1].to_i+2000
    member.cc_month_exp = new_expiration_date[2..3]
  when 'CLOSED'
    if member.active == 1 or member.trial == 1
      DeactivationJob.new(member.id, 'Hard decline. AUS answered account CLOSED wont be able to bill').perform
      member.cs_next_bill_date = nil
    end
  else
    log "Member id ##{member.id} with response #{response_code} ask for an action. #{line}"
  end
  member.save
  if update_cs
    Delayed::Job.enqueue(UpdateJob.new(member.id))
  end
end

def account_updater_file_status
  ################################################
  ########## new file!
  ################################################
  conn = Faraday.new(:url => @url, :ssl => {:verify => false})
  result = conn.get '/srv/api/ausStatus?', { 
    :userId => @username, 
    :userPass => @password, 
    :merchId => @merchant, 
    :statusFilter => 'NEW'
  }    
  answer = Rack::Utils.parse_nested_query(result.body)
  puts answer.inspect
  0.upto(answer['statusCount'].to_i-1) do |i|
    request_file_by_id answer["rspfId_#{i}"], "rsp-"+answer["reqfId_#{i}"]+"-#{Time.now.to_i}.txt"
  end
end

def log(text)
  Rails.logger.info "AUS Updater: #{text}"
  puts text
end

if ARGV[0] == 'store_file'
  local_filename = store_file
  puts local_filename
elsif ARGV[0] == 'store_and_send'
  local_filename = store_file
  puts local_filename
  send_file_to_mes local_filename
elsif ARGV[0] == 'send'
  send_file_to_mes ARGV[1]
elsif ARGV[0] == 'download_all'
  account_updater_file_status
elsif ARGV[0] == 'download'
  request_file_by_id ARGV[1], ARGV[2]
elsif ARGV[0] == 'parse_file'
  parse_file ARGV[1]
else
  puts "Arguments need: send - download_all - download"
end
