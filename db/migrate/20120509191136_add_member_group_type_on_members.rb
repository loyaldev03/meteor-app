class AddMemberGroupTypeOnMembers < ActiveRecord::Migration
  def up
    add_column :members, :member_group_type_id, :integer

    Club.all.each do |club|
      ['VIP', 'Celebrity', 'Notable'].each do |name|
        m = MemberGroupType.new
        m.name= name
        m.club_id = club.id
        m.save
      end
    end
  end

  def down
    remove_column :members, :member_group_type_id
  end
end
