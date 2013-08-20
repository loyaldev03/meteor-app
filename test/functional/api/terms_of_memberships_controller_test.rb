require "test_helper"


class Api::TermsOfMembershipsControllerTest < ActionController::TestCase

	setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id
    @terms_of_membership_second = FactoryGirl.create :terms_of_membership_with_gateway, :club_id => @club.id, :name => "secondTom"
    sign_in @admin_user
	end

	test "Change TOM throught API - different TOM - active member" do
    @saved_member = create_active_member(@terms_of_membership, :active_member, nil, {}, { :created_by => @admin_user }) 
    post(:change, { :member_id => @saved_member.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
		@saved_member.reload
    assert_equal @saved_member.current_membership.terms_of_membership_id, @terms_of_membership_second.id
    assert_equal @saved_member.operations.where(description: "Save the sale from TOM(#{@terms_of_membership.id}) to TOM(#{@terms_of_membership_second.id})").first.operation_type, Settings.operation_types.save_the_sale_through_api
	end

	test "Do not allow change TOM throught API to same TOM - active member" do
    @saved_member = create_active_member(@terms_of_membership, :active_member, nil, {}, { :created_by => @admin_user }) 
    post(:change, { :member_id => @saved_member.id, :terms_of_membership_id => @terms_of_membership.id, :format => :json} )
    assert @response.body.include? "Nothing to change. Member is already enrolled on that TOM."
	end

	test "Change TOM throught API - different TOM - provisional member" do
    @saved_member = create_active_member(@terms_of_membership, :provisional_member, nil, {}, { :created_by => @admin_user }) 
    post(:change, { :member_id => @saved_member.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
		@saved_member.reload
    assert_equal @saved_member.current_membership.terms_of_membership_id, @terms_of_membership_second.id
    assert_equal @saved_member.operations.where(description: "Save the sale from TOM(#{@terms_of_membership.id}) to TOM(#{@terms_of_membership_second.id})").first.operation_type, Settings.operation_types.save_the_sale_through_api
	end

	test "Do not allow change TOM throught API to same TOM - provisional member" do
    @saved_member = create_active_member(@terms_of_membership, :provisional_member, nil, {}, { :created_by => @admin_user }) 
    post(:change, { :member_id => @saved_member.id, :terms_of_membership_id => @terms_of_membership.id, :format => :json} )
    assert @response.body.include? "Nothing to change. Member is already enrolled on that TOM."
	end

	test "Do not allow change TOM throught API - applied member" do
    @saved_member = create_active_member(@terms_of_membership, :applied_member, nil, {}, { :created_by => @admin_user }) 
    post(:change, { :member_id => @saved_member.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
    assert @response.body.include? "Member status does not allows us to change the terms of membership."
	end

	test "Do not allow change TOM throught API - lapsed member" do
    @saved_member = create_active_member(@terms_of_membership, :applied_member, nil, {}, { :created_by => @admin_user }) 
    post(:change, { :member_id => @saved_member.id, :terms_of_membership_id => @terms_of_membership_second.id, :format => :json} )
    assert @response.body.include? "Member status does not allows us to change the terms of membership."
	end
end