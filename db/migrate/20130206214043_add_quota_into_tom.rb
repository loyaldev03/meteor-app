class AddQuotaIntoTom < ActiveRecord::Migration
  def up
    add_column :terms_of_memberships, :quota, :integer, :default => 1
    TermsOfMembership.all.each do |tom|
      tom.quota = ( tom.installment_type == '1.month' ? 1 : 12 )
      tom.save
    end
  end

  def down
    remove_column :terms_of_memberships, :quota
  end
end
