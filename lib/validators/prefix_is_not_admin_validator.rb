class PrefixIsNotAdminValidator < ActiveModel::EachValidator  
  def validate(record)
  	if !record.prefix.nil?
      if record.prefix.include?('admin')
        record.errors[:prefix] << 'The admin word is reserved!'
      end
    end
  end
end
