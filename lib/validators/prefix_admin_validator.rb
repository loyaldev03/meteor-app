class PrefixAdminValidator < ActiveModel::EachValidator  
  def validate(record)
    if record.prefix.include?('admin')
      record.errors[:prefix] << 'Need a name starting with X please!'
    end
  end
end