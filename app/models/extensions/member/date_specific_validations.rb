module Extensions
  module Member
    module DateSpecificValidations
      def birth_date_specific_validations!
        lambda {|member| member.birth_date and member.birth_date < '1900-01-01'.to_date } ? true : false
      end
    end
  end
end 