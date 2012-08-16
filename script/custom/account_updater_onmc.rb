require '../../config/environment.rb'

## ONMC version

@password = 'do3!lAjo5'
@merchant = '941000110028'
@username = '941000110028AUS'
@url = 'https://www.merchante-solutions.com/'
@folder = "#{RAILS_ROOT rescue Rails.root}/files/mes_account_updater"

def send_file_to_mes
  ################################################
  ########## new file!
  ################################################
  local_filename = "#{@folder}/onmc_account_updater_#{Date.today}.txt"
  file = File.open(local_filename, 'w')

  # add header
  record_type, version_id, merchant_id = 'H1', '100000', "%-32s" % @merchant
  file.write [ record_type, version_id, merchant_id ].join + "\n"

  count = 0
  # members with expired credit card and active
  Member.find(:all, 
    :conditions => [ 
      " (active = 1 or trial = 1) and ((cc_month_exp <= ? and cc_year_exp = ?) or cc_year_exp < ?) ", 
      Date.today.month, Date.today.year, Date.today.year 
    ] , :limit => 10
  ).each do |member|
    
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
      'MC'
    else
      nil
    end
    # only master and visa allowed
    next if account_type.nil?

    # add cc line
    record_type, account_number, expiration_date, descretionary_data = 'D1', "%-32s" % member.cc_number, 
      member.cc_year_exp.to_s[2..3]+("%02d" % member.cc_month_exp), member.id

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
    file.write answer['rspMessage']
    file.close
    parse_file full_filename
  end
end

def parse_file(filename)
  File.open(filename).each do |line|
    # do not parse header or trailers.
    next if line[0] == 'H' or line[0] == 'T'
    # TODO: IMPROVEMENT: we can add a flag on each credit card to know if it was or nor processed
    record_type = line[0..1]
    old_account_type = line[2..5]
    old_account_number = line[6..37]
    old_expiration_date = line[38..41]
    new_account_type = line[42..45]
    new_account_number = line[46..77]
    new_expiration_date = line[78..81]
    response_code = line[82..89]
    response_source = line[90..91]
    discretionary_data = line[92..123]

    member = Member.find discretionary_data
    if member.nil?
      log "Member id not found ##{discretionary_data} while parsing. #{line}"
    else
      case response_code
      when 'NEWACCT'
        member.cc_number = new_account_number
        member.cc_year_exp = new_expiration_date[0..1].to_i+2000
        member.cc_month_exp = new_expiration_date[2..3]
        member.save
      when 'NEWEXP'
        member.cc_year_exp = new_expiration_date[0..1].to_i+2000
        member.cc_month_exp = new_expiration_date[2..3]
        member.save
      else
        log "Member id ##{discretionary_data} with response #{response_code} ask for an action. #{line}"
      end
    end
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
  0..answer['statusCount'].to_i do |i|
    request_file_by_id answer["reqfId_#{i}"], answer["reqfName_#{i}"]
  end
end

def log(text)
  Rails.logger.info "AUS Updater: #{text}"
end

if ARGV[0] == 'send'
  send_file_to_mes
elsif ARGV[0] == 'download_all'
  account_updater_file_status
elsif ARGV[0] == 'download'
  request_file_by_id ARGV[1], ARGV[2]
else
  puts "Arguments need: send - download_all - download"
end

