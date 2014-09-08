class LyrisService
  def initialize
    @domain = Settings.lyris_service.domain
    @url = Settings.lyris_service.url
    @site_id = nil
    @password = Settings.lyris_service.password
  end

  def site_id=(s)
    @site_id = s
  end

  def subscribe_user!(communication)
    action = user_exists?(communication.external_attributes[:mlid], communication.email) ? 'update' : 'add'
    send_request!(communication.external_attributes[:mlid],'record', action, true) do |body|
      body.DATA communication.email, :type => 'email'
      body.DATA communication.user.first_name, :type => 'demographic', :id => 1
      body.DATA communication.user.last_name, :type => 'demographic', :id => 2
      # Demographic data from ONMC . Do v5 have diff demographic IDs?
      body.DATA communication.user.id, :type => 'demographic', :id => 41166
      body.DATA communication.user.next_retry_bill_date, :type => 'demographic', :id => 47171
      body.DATA communication.user.terms_of_membership.installment_amount, :type => 'demographic', :id => 48297
      body.DATA communication.external_attributes[:trigger_id], :type => 'extra', :id => 'trigger_id'
      body.DATA "yes", :type => 'extra', :id => 'trigger'
      # Rails.logger.debug YAML.dump(body)
    end
  end

  def send_email!(mlid, trigger_id, email)
    send_request!(mlid, 'triggers', 'fire-trigger', true) do |body|
      body.DATA trigger_id,    :type => 'extra', :id => 'trigger_id'
      body.DATA email, :type => 'extra', :id => 'recipients'
    end    
  end

  # LyrisService.new.unsubscribed?(82416, 'debi1@zoomtown.com')
  def unsubscribed?(mlid, email_address)
    query_data_detailed!(mlid, email_address).include?('<DATA type="extra" id="state">unsubscribed</DATA>')
  end

  private
    def query_data_detailed!(mlid, email_address)
      send_request!(mlid,'record', 'query-data', true) do |body|
        body.DATA email_address, :type => 'email'
      end
    end

    def user_exists?(mlid, email_address)
      send_request!(mlid,'record', 'query-data') do |body|
        body.DATA email_address, :type => 'email'
      end
    end

    def send_request!(mlid, type, activity, return_body = false)
      xml = Builder::XmlMarkup.new :target => (input = '')
      xml.DATASET do
        xml.SITE_ID @site_id
        xml.MLID mlid
        xml.DATA @password, :type => 'extra', :id => 'password'
        yield xml
      end
      # Rails.logger.debug YAML.dump(xml)

      conn = Net::HTTP.new(@domain, 443)
      conn.use_ssl = true
      conn.verify_mode = OpenSSL::SSL::VERIFY_NONE

      response = conn.start do |http|
        req = Net::HTTP::Post.new(@url)
        req.set_form_data("activity" => activity, "type" => type, "input" => input)
        http.request(req).body
      end

      return_body ? response : response.include?("<TYPE>success</TYPE>")
    end

end