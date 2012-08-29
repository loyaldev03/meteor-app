class RemoveEnrolllmentInfoFromTransactions < ActiveRecord::Migration
  def up
    remove_column :transactions, :enrollment_info_id
    add_column :members, :cohort, :string
    Club.all.each do |c|
      c.members.each do |m|
        next if m.join_date.nil? or m.enrollment_infos.first.nil?
        m.update_attribute :cohort , Member.cohort_formula(m.join_date, m.enrollment_infos.first, c.time_zone)
        m.transactions.each { |t| t.update_attribute :cohort, m.cohort }
      end
    end
  end

  def down
    add_column :transactions, :enrollment_info_id, :integer
    remove_column :members, :cohort
  end
end
