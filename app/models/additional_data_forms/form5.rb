# Club id 5 is AmerigoRV
class Form5 < Bureaucrat::Form
  extend Bureaucrat::Quickfields

  # string  :nickname, max_length: 50
  # string  :realname, required: false
  # email   :email
  # integer :age, min_value: 0
  # date :first_grade
  # choice :options, [ :test, :salida, :entrada ] 
  # boolean :newsletter, required: false

  choice :financing, [ '', 'AmeriGO', 'Affiliated Dealer', 'Other Channel' ], required: false
  date :date_purchased_from, required: false, label: "Date purchased from (format is yyyy-mm-dd)"
  choice :extended_warranty, [ '', 'AmeriGO', 'Affiliated Dealer', 'Other Channel' ], required: false
  choice :roadside_assistance, [ '', 'AmeriGO', 'Affiliated Dealer', 'Other Channel' ], required: false
  choice :insurance, [ '', 'AmeriGO', 'Affiliated Dealer', 'Other Channel' ], required: false

end
