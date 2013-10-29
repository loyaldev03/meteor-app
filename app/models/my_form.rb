class MyForm < Bureaucrat::Form
  extend Bureaucrat::Quickfields

  string  :nickname, max_length: 50
  string  :realname, required: false
  email   :email
  integer :age, min_value: 0
  boolean :newsletter, required: false

  # Note: Bureaucrat doesn't define save
  def save
#    user
  end
end
