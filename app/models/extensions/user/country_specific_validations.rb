module Extensions
  module User
    module CountrySpecificValidations
      def validations_for(country)
        country     = country.downcase
        all         = Settings.validations
        defaults    = all.defaults
        allsets     = all.sets
        countries   = all.countries
        raise ArgumentInvalid unless countries.key?(country)

        validations = countries[country].dup
        sets = validations.delete('sets').inject({}) { |sum,elem| sum.merge allsets[elem] } # no #slice on SettingsLogic
        defaults.merge(sets).merge(validations)
      end

      def supported_countries
        Settings.validations.supported_countries.map &:upcase
      end

      def country_name(cc)
        I18n.t cc.downcase, scope: 'activerecord.attributes.user.supported_countries'
      end

      def country_specific_validations!
        self.supported_countries.each do |cc|
          logger.info "User validations for country: #{cc}"
          self.validations_for(cc).each do |attr,opts|
            opts = opts.merge if: lambda { |m| m.country.present? && (m.country.downcase == cc.downcase) }
            self.validates attr, opts
          end
        end
      end
    end
  end
end
