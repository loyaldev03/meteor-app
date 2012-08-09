require 'config/environment.rb'

@password = 
@merchant = '941000110028'
@username = '941000110028AUS'


def send_file_to_mes
  ################################################
  ########## new file!
  ################################################
  local_filename = "#{RAILS_ROOT}/mes_account_updater_files/onmc_account_updater_#{Date.today}.txt"
  file = File.open(local_filename, 'w')

  # add header
  record_type, version_id, merchant_id = 'H1', '100000', "%-32s" % '941000110028'
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
    when 
      'visa': 'VISA'
    when 
      'master': 'MC'
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

  conn = Faraday.new(:url => 'https://www.merchante-solutions.com/', :ssl => {:verify => false}) do |builder|
    builder.request :multipart
    builder.request :url_encoded
  end

  result = conn.post '/srv/api/ausUpload?', { 
    :userId => @username, 
    :userPass => @password, 
    :merchId => @merchant, 
    :attachment => Faraday::UploadIO.new(local_filename, 'multipart/form-data')
  }    
end


def account_updater_file_status
  ################################################
  ########## new file!
  ################################################
  conn = Faraday.new(:url => 'https://www.merchante-solutions.com/', :ssl => {:verify => false})
  result = conn.get '/srv/api/ausStatus?', { 
    :userId => @username, 
    :userPass => @password, 
    :merchId => @merchant, 
    :statusFilter => 'NEW'
  }    
  answer = Rack::Utils.parse_nested_query(result.body)

  0..answer['statusCount'].to_i do |i|
    file_id = answer["reqfId_#{i}"]
    result = conn.get '/srv/api/ausDownload?', { 
      :userId => @username, 
      :userPass => @password, 
      :merchId => @merchant, 
      :rspfId => file_id
    }    
    file = File.open("#{RAILS_ROOT}/mes_account_updater_files/#{answer["reqfName_#{i}"]}", 'w')
    file.write result.body.rspMessage 
    file.close
  end
end


send_file_to_mes
account_updater_file_status

