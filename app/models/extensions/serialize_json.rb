module Extensions
  module SerializeJson
    extend ActiveSupport::Concern

    included do
      extend ClassMethods
    end

    module ClassMethods
      def serialize_json(*columns)
        raise ArgumentError if columns.blank?
        columns.each do |col|
          define_method col do 
            begin
              JSON.parse self.send("raw_#{col}")
            rescue JSON::ParserError
              Rails.logger.warn " * * SerializeJson ERROR for #{self.class.name}##{self.id}##{col}: #{$!} / #{$@ * "\n\t"}"
              nil
            end
          end

          define_method "raw_#{col}" do 
            read_attribute col
          end

          define_method "#{col}=" do |value|
            value = (String === value) && (JSON.parse(value) rescue false) ? value : value.to_json
            JSON.parse self.send("raw_#{col}=", value)
          end

          define_method "raw_#{col}=" do |value|
            begin
              JSON.parse value # throw an error if invalid
              write_attribute col, value
            rescue JSON::ParserError
              Rails.logger.warn " * * SerializeJson ERROR for #{self.class.name}##{self.id}##{col}: #{$!} / #{$@ * "\n\t"}"
            end
          end
        end
      end
    end
  end
end
