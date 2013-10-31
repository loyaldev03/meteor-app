# This class is for testing purpouses.
class Form10 < Bureaucrat::Form
  extend Bureaucrat::Quickfields

  string  :nickname, max_length: 50
  string  :realname, required: false
  date :first_grade
  choice :options, [ :test, :salida, :entrada ] 

end
