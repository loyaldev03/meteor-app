class NameIsNotAdminValidator < ActiveModel::EachValidator  
  def validate(record)
  	if !record.name.nil?
      if record.name.include?('admin')
        record.errors[:name] << 'The admin word is reserved!'
      end
    end
  end
end
