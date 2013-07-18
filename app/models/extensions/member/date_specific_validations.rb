module Extensions
  module Member
    module DateSpecificValidations
      def birth_date_specific_validations!
        if !self.birth_date.nil? and self.birth_date < '1900-01-01'.to_date
          
        end
      end
    end
  end
end 