naamma_id =  4

def log(msg)
  out = "#{$$} #{Time.zone.now.to_s(:db).gsub(/[^\d]/, '')} | #{String === msg ? msg : msg.inspect}\n"
  print out
  @log << out
end

tall = Time.zone.now
members = Member.where(" status != 'lapsed' and club_id = #{naamma_id} ").limit(300)
begin
  @log = File.open("#{Rails.root}/log/credit_card_token_update-script-#{$$}.log", 'a+')
  log "* Starting - #{members.size} members to process"
  members.each do |member|
    begin
      log "  * processing member ##{member.id}"
      active_credit_card = member.active_credit_card

      next if active_credit_card.gateway != "authorize_net"

      if active_credit_card.token == 'a'
        new_credit_card = CreditCard.new expire_year: active_credit_card.expire_year, 
                        expire_month: active_credit_card.expire_month
        new_credit_card.gateway = 'mes'
        new_credit_card.token = 'a'
        new_credit_card.last_digits = '0000'
        member.add_new_credit_card(new_credit_card, nil)        
      else
        cc_number = Encryptor.decrypt(Base64::decode64(active_credit_card.token), :key => Digest::SHA256.hexdigest(Settings.xxxyyyzzz), :algorithm => 'bf')

        ActiveMerchant::Billing::CreditCard.require_verification_value = false
        credit_card = ActiveMerchant::Billing::CreditCard.new(
          :number     => cc_number,
          :month      => active_credit_card.expire_month,
          :year       => active_credit_card.expire_year,
          :first_name => member.first_name,
          :last_name  => member.last_name
        )

        ActiveMerchant::Billing::Base.mode = :production
        gateway = ActiveMerchant::Billing::MerchantESolutionsGateway.new(
           :login    => '',
           :password => '',
           :merchant_key => 'SAC Inc')
        response = gateway.store(credit_card)
        log "      => response #{response.inspect}"

        if response.params['error_code'] == "000"
          new_credit_card = CreditCard.new expire_year: active_credit_card.expire_year, 
                          expire_month: active_credit_card.expire_month
          new_credit_card.gateway = 'mes'
          new_credit_card.cc_type = credit_card.brand
          new_credit_card.token = response.params['transaction_id']
          new_credit_card.last_digits = cc_number.last(4)
          member.add_new_credit_card(new_credit_card, nil)
        else
          log "     Response from MeS not success!!!!"
        end
      end
    rescue
      log "    [!] failed: #{$!.inspect}\n\t#{$@[0..9] * "\n\t"}"
    end
  end
ensure
  log "It all took #{Time.zone.now - tall}"
  @log.close
end

