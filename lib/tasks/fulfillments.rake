namespace :fulfillments do	
	desc "Create fulfillment report for Brian Miller."
	task :generate_fulfillment_naamma_report => :environment do
		fulfillment_file = FulfillmentFile.new 
		fulfillment_file.agent = Agent.find_by_email('batch@xagax.com')
		# fulfillment_file.club = Club.find 4
		fulfillment_file.club = Club.find 2
		fulfillment_file.product = "KIT-CARD"
		fulfillment_file.save!

		fulfillments = Fulfillment.includes(:member).where( ["members.club_id = ? AND fulfillments.created_at BETWEEN ? AND ? and fulfillments.status = 'not_processed'", fulfillment_file.club_id, Time.zone.now-7.days, Time.zone.now ])

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

    temp = Tempfile.new("posts.xlsx") 
    
    package.serialize temp.path
    Notifier.fulfillment_naamma_report(temp, fulfillment_file.fulfillments.count).deliver!
    
    temp.close 
    temp.unlink
	end
end