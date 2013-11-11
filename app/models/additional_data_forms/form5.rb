# Club id 5 is AmerigoRV
class Form5 < Bureaucrat::Form
  extend Bureaucrat::Quickfields
  choice :financing, [ '', 'AmeriGO', 'Affiliated Dealer', 'Other Channel' ], required: false
  date :date_purchased_from, required: false, min: '1900-01-01'.to_date, label: "Date purchased from (format is yyyy-mm-dd)"
  choice :extended_warranty, [ '', 'AmeriGO', 'Affiliated Dealer', 'Other Channel' ], required: false
  choice :roadside_assistance, [ '', 'AmeriGO', 'Affiliated Dealer', 'Other Channel' ], required: false
  choice :insurance, [ '', 'AmeriGO', 'Affiliated Dealer', 'Other Channel' ], required: false
end
