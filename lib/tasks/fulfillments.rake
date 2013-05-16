namespace :fulfillments do	
	desc "Create fulfillment report for Brian Miller."
	task :generate_fulfillment_naamma_report => :environment do
		fulfillment_file = FulfillmentFile.new 
		fulfillment_file.agent = Agent.find_by_email('batch@xagax.com')

		if Rails.env=='prototype'
			fulfillment_file.club = Club.find 41
		elsif Rails.env=='production'
			fulfillment_file.club = Club.find 4
		end
			
		fulfillment_file.product = "KIT-CARD"
		fulfillment_file.save!

		fulfillments = Fulfillment.includes(:member).where( 
			["members.club_id = ? AND fulfillments.assigned_at BETWEEN ? 
		  	AND ? and fulfillments.status = 'not_processed' 
			  AND fulfillments.product_sku like 'KIT-CARD'", fulfillment_file.club_id, 
			Time.zone.now-7.days, Time.zone.now ])

		fulfillments.each do |fulfillment|
	    fulfillment_file.fulfillments << fulfillment
	    fulfillment.set_as_in_process
  	end
		fulfillment_file.save!

    package = Axlsx::Package.new									
    package.workbook.add_worksheet(:name => "Fulfillments") do |sheet|
    	sheet.add_row [ 'First Name', 'Last Name', 'Member Number', 'Membership Type (fan/subscriber)', 
    		             'Address', 'City', 'State', 'Zip','Phone number' ,'Join date', 'Membership expiration date' ]
    	unless fulfillments.empty?
		  	fulfillments.each do |fulfillment|
		  		member = fulfillment.member
		  		membership = member.current_membership
		      row = [ member.first_name, member.last_name, member.id, 
		      			  membership.terms_of_membership.name, member.address, 
		      			  member.city, member.state, "=\"#{member.zip}\"", member.full_phone_number,
		      			  I18n.l(member.join_date, :format => :only_date_short), 
		      			  (I18n.l membership.cancel_date, :format => :only_date_short if membership.cancel_date ) 
		      			]
		    	sheet.add_row row 
		    end
    	end
    end

    temp = Tempfile.new("naamma_kit-card_report.xlsx") 
    
    package.serialize temp.path
    Notifier.fulfillment_naamma_report(temp, fulfillment_file.fulfillments.count).deliver!
    
    temp.close 
    temp.unlink

    fulfillment_file.processed
	end

	desc "Create fulfillment report for sloops products reated to Naamma."
	task :generate_sloop_naamma_report => :environment do
		require 'csv'
		require 'net/ftp'

		fulfillment_file = FulfillmentFile.new 
		fulfillment_file.agent = Agent.find_by_email('batch@xagax.com')

		if Rails.env=='prototype'
			fulfillment_file.club = Club.find 41
		elsif Rails.env=='production'
			fulfillment_file.club = Club.find 4
		end

		fulfillments = Fulfillment.includes(:member).where( 
			["members.club_id = ? AND fulfillments.assigned_at BETWEEN ? 
		  	AND ? and fulfillments.status = 'not_processed' 
			  AND fulfillments.product_sku != 'KIT-CARD'", fulfillment_file.club_id, 
			Time.zone.now-7.days, Time.zone.now ])

    temp_file = "#{I18n.l(Time.zone.now, :format => :only_date)}_sloop_naamma.csv"
		CSV.open( temp_file, "w" ) do |csv|
		  csv << [ 'First Name', 'Last Name', 'Product Choice', 'address', 'city', 'state', 'zip', 'join date', 'phone number' ]
    	unless fulfillments.empty?
		  	fulfillments.each do |fulfillment|
		  		member = fulfillment.member
		  		membership = member.current_membership
				  csv << [member.first_name, member.last_name, fulfillment.product_sku, member.address, 
				  				member.city, member.state, "#{member.zip}"	,
				  				I18n.l(member.join_date, :format => :only_date_short), 
		      			  member.full_phone_number]

		     	fulfillment_file.fulfillments << fulfillment
	  		  fulfillment.set_as_in_process
		    end
			end
		end
		fulfillment_file.product = "SLOOPS"
		fulfillment_file.save!
    
    begin	
		  ftp = Net::FTP.new('ftp.stoneacreinc.com')
  		ftp.login(user = "phoenix", passwd = "ph03n1xFTPu$3r")
			folder = fulfillment_file.club.name
	  	begin
	    	ftp.mkdir(folder)
	    	ftp.chdir(folder)
  	  rescue Net::FTPPermError
  	  	ftp.chdir(folder)
  	  end
	    ftp.putbinaryfile(temp_file, File.basename(temp_file))
    ensure
    	ftp.quit()
    end

    fulfillment_file.processed
    File.delete(temp_file)
	end
end