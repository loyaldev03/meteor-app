class CreateMemberships < ActiveRecord::Migration
  def up
    create_table :memberships do |t|
      t.string   "member_id",                   :limit => 36
      t.string   "status"
      t.integer  "terms_of_membership_id", :limit => 8
      t.datetime "join_date"
      t.datetime "cancel_date"
      t.integer  "created_by_id"
      t.integer  "quota",                                :default => 0
      t.string   "cohort"
      t.timestamps
    end
    add_column :members, :current_membership_id, :integer
    add_column :enrollment_infos, :membership_id, :integer
    add_column :transactions, :membership_id, :integer
    Member.where("terms_of_membership_id is not null").find_in_batches do |group|
      group.each do |member|
        m = Membership.new 
        m.status = member.status
        m.terms_of_membership_id = member.terms_of_membership_id
        m.join_date = member.join_date
        m.cancel_date = member.cancel_date
        m.created_by_id = member.created_by_id
        m.quota = member.quota
        m.save
        member.update_attribute :current_membership_id, m.id
        unless member.enrollment_infos.first.nil?
          member.enrollment_infos.first.update_attribute :membership_id, m.id
        end
      end
    end
    [ :terms_of_membership_id, :join_date, :cancel_date, :created_by_id, :quota].each do |column|
      remove_column :members, column
    end
    drop_table :versions
  end

  def down
    alter_table :members do |t|
      t.integer  "terms_of_membership_id", :limit => 8
      t.datetime "join_date"
      t.datetime "cancel_date"
      t.integer  "created_by_id"
      t.integer  "quota",                                :default => 0
    end
    Membership.all.each do |membership|
      m = membership.member
      m.status = membership.status
      m.terms_of_membership_id = membership.terms_of_membership_id
      m.join_date = membership.join_date
      m.cancel_date = membership.cancel_date
      m.created_by_id = membership.created_by_id
      m.quota = membership.quota
      m.save
    end
    remove_column :members, :current_membership_id
    remove_column :enrollment_infos, :membership_id
    remove_column :transactions, :membership_id
    drop_table :memberships
    # create versions table again
    create_table :versions do |t|
      t.string   :item_type, :null => false
      t.integer  :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :whodunnit
      t.text     :object
      t.datetime :created_at
    end
    add_index :versions, [:item_type, :item_id]

  end
end
