class EmailValidator < ActiveModel::Validator  
	def validate(record)
		parts = record.email.to_s.split("@")
		valid = if parts.count == 2
			((parts.first =~ /^[0-9a-zA-Z\-_]([-_\.]?[+?]?[0-9a-zA-Z\-_])*$/).nil? ? false : true) and
			((parts.last =~ /^(([0-9a-zA-Z]+[-]*[0-9a-zA-Z]?)+\.)+[a-zA-Z]{2,9}$/).nil? ? false : true) 
	  else 
	  	false
	  end
	  record.errors[:email] << ("email address is invalid") unless valid
	end
end