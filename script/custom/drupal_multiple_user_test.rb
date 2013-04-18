  #!/bin/ruby
  APP_PATH = File.expand_path('../../../config/application',  __FILE__)
  require File.expand_path('../../../config/boot',  __FILE__)
  ENV["RAILS_ENV"] ||= "staging"
  require APP_PATH
  Rails.application.require_environment!


  def fieldmap(index)
    map = { 
      mail: "testingperformance#{index}@xagax.com",
      field_profile_firstname: { 
        und: [ 
          { 
            value: "Testing performance"
          } 
        ] 
      }, 
      field_profile_lastname: { 
        und: [ 
          { 
            value: "Testing performance"
          } 
        ] 
      }, 
      field_profile_gender: { 
        und: { select: ("_none") }
      },
      field_profile_phone_type: { 
        und: ( 
            { "select" => "_none" }
            ) 
      },
      field_profile_phone_country_code: { 
        und: [ 
          { 
            value: 978
          } 
        ] 
      },
      field_profile_phone_area_code: { 
        und: [ 
          { 
            value: 987
          } 
        ] 
      },
      field_profile_phone_local_number: { 
        und: [ 
          { 
            value: 789
          } 
        ] 
      },
      field_profile_club_cash_amount: { 
        und: [{ value: 10 }]
      },
      field_profile_dob: {
        und: [
          {
            value: { date: '' }
          }
        ]
      },
      field_profile_address_address:{
        und:[ 
          {
            country: 'US',
            administrative_area: 'NC',
            locality: 'Charlotte',
            postal_code: '15987',
            thoroughfare: '6729 Wakehurst Rd.'
          } 
        ]
      },
    }
    
    map.merge!({
      pass: SecureRandom.hex, 
      field_phoenix_member_id: {
        und: [ { value: index } ]
      }
    })
    
    # Add credit card information
    map.merge!({
      field_profile_cc_month: {
        und: { value: 10 }
      },
      field_profile_cc_year: {
        und: { value: 2015 }
      },
      field_profile_cc_number: {
        und: [{
          value: "XXXX-XXXX-XXXX-0000"
        }]
      }
    })

    map
  end

  def init(quantity)
    tz = Time.zone.now
    conn = Club.find(9).drupal
    saved_id = []
    wrong_count = 0
    i = 900
    puts "Starting creation [#{I18n.l(Time.zone.now, :format =>:dashed)}]"
    quantity.times do
      res = conn.post '/api/user', fieldmap(i)
      i = i+1
      if res and res.status == 200
        saved_id << res.body['uid']
        print(".")
      else
        wrong_count = wrong_count+1
        puts res.body.class == Hash ? res.body[:message] : res.body
        print("F")
      end
    end

    puts ""
    puts "Finished creation [#{I18n.l(Time.zone.now, :format =>:dashed)}]"
    puts "Attemps: #{quantity}"
    puts "Success: #{quantity - wrong_count}"
    puts "Failed: #{wrong_count}"
    puts "Starting deletion [#{I18n.l(Time.zone.now, :format =>:dashed)}]"
    
    tz = Time.zone.now
    wrong_count = 0
    saved_id.each do |uid|  
      res = conn.delete('/api/user/%{drupal_id}' % { drupal_id: uid })
      if res and res.status == 200
        print(".")
      else
        wrong_count = wrong_count+1
        puts res.body.class == Hash ? res.body[:message] : res.body
        print("F")
      end
    end

    puts ""
    puts "Attemps: #{saved_id.count}"
    puts "Success: #{saved_id.count - wrong_count}"
    puts "Failed: #{wrong_count}"
    puts "It all took: #{Time.zone.now-tz}"
    puts "Finished deletion [#{I18n.l(Time.zone.now, :format =>:dashed)}]"
  end

  quantity_members = ARGV[0].to_i
  init( quantity_members )