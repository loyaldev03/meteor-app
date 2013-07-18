class BirthDateValidator < ActiveModel::EachValidator  
  def validate(record)
    if !record.birth_date.nil? and record.birth_date < '1900-01-01'.to_date
      record.errors[:birth_date] << I18n.t('error_messages.birth_date_is_invalid')
    end
  end
end