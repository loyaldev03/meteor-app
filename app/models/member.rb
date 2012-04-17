class Member < ActiveRecord::Base
  attr_accessible :address, :bill_date, :city, :country, :created_by, :description, 
      :email, :enroll_attempts, :external_id, :first_name, :home_phone, 
      :join_date, :last_name, :member_cancel_reason_type_id, :status, 
      :next_bill_date, :quota, :state, :terms_of_membership_id, :work_phone, :zip

      # t.integer :member_cancel_reason_type_id # TODO

end
