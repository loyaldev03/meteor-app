class Form8 < Bureaucrat::Form
  extend Bureaucrat::Quickfields

  string  :nickname, max_length: 50
  string  :realname, required: false
  email   :email
  integer :age, min_value: 0
  date :first_grade
  choice :options, [ :test, :salida, :entrada ] 
  boolean :newsletter, required: false

end
