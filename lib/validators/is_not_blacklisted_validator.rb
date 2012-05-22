class IsNotBlacklistedValidator < ActiveModel::EachValidator
  def validate(record)
	if record.blacklisted
      record.errors[:active] << 'The credit card is blacklisted'
    end
  end
end