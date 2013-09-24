class EmailValidator < ActiveModel::EachValidator  
	def validate(record)
		valid = false
		begin 
			email = Mail::Address.new(record.email)
			valid = if email.address.split("@").count > 1 
				((email.address.split("@").first =~ /^[0-9a-zA-Z\-_]([-_\.]?[+?]?[0-9a-zA-Z\-_])*$/).nil? ? false : true) and
				((email.domain =~ /^(([0-9a-zA-Z]+[-]*[0-9a-zA-Z]?)+\.)+[a-zA-Z]{2,9}$/).nil? ? false : true) 
		  end
		rescue
			####
		end
	  record.errors[:email] << ("email address is invalid") unless valid
	end
end