class Member < ActiveRecord::Base
  belongs_to :terms_of_membership
  belongs_to :club
  belongs_to :partner
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'

  attr_accessible :address, :bill_date, :city, :country, :created_by, :description, 
      :email, :enroll_attempts, :external_id, :first_name, :home_phone, 
      :join_date, :last_name, :member_cancel_reason_type_id, :status, 
      :next_bill_date, :quota, :state, :terms_of_membership_id, :work_phone, :zip, 
      :club_id, :partner_id

      # t.integer :member_cancel_reason_type_id # TODO


  validates :first_name, :presence => true
   # TODO: add the following attributes as required.
   #   t.string :last_name
   #   t.string :email
   #   t.string :address
   #   t.string :city
   #   t.string :state
   #   t.string :zip
   #   t.string :country
   #   t.integer :terms_of_membership_id, :limit => 8
    

   # TODO => sacar esto
      # t.string :status
      # t.integer :bill_date
      # t.integer :created_by
      # t.datetime :next_bill_date
      # t.integer :quota, :default => 0


end
