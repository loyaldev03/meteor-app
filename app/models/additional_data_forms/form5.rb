# # Club id 5 is AmerigoRV
# class Form5 < Bureaucrat::Form
#   extend Bureaucrat::Quickfields
#   choice :financing, [ '', 'AmeriGO', 'Affiliated Dealer', 'Other Channel' ], required: false
#   date :financing_date_purchased_from, required: false, min: '1900-01-01'.to_date, label: "Financing date purchased from (format is yyyy-mm-dd)"
#   choice :extended_warranty, [ '', 'AmeriGO', 'Affiliated Dealer', 'Other Channel' ], required: false
#   date :extended_date_purchased_from, required: false, min: '1900-01-01'.to_date, label: "Extended date purchased from (format is yyyy-mm-dd)"
#   choice :roadside_assistance, [ '', 'AmeriGO', 'Affiliated Dealer', 'Other Channel' ], required: false
#   date :roadside_date_purchased_from, required: false, min: '1900-01-01'.to_date, label: "Roadside date purchased from (format is yyyy-mm-dd)"
#   choice :insurance, [ '', 'AmeriGO', 'Affiliated Dealer', 'Other Channel' ], required: false
#   date :insurance_date_purchased_from, required: false, min: '1900-01-01'.to_date, label: "Insurance date purchased from (format is yyyy-mm-dd)"
# end
