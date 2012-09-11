class CountrySpecificValidator < ActiveModel::EachValidator  
  def validate(record)
    if get_regex(record.country).match(record.zip).nil?
      record.errors[:zip] << 'The zip code is not valid for the selected country.'
    end
  end

  def get_regex(country)
    case country
      when "US"
        return /^\d{5}([\-]?\d{4})?$/
      when "CA"
        return /^[ABCEGHJKLMNPRSTVXYabceghjklmnprstvxy]{1}[0-9]{1}[A-Za-z]{1}[\s]{1}[0-9]{1}[A-Za-z][0-9]{1}$/
      else
        return /^[0-9A-Za-z-]+$/
    end
  end

end
