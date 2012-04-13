require 'test_helper'

class TermsOfMembershipsControllerTest < ActionController::TestCase
  setup do
    @terms_of_membership = terms_of_memberships(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:terms_of_memberships)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create terms_of_membership" do
    assert_difference('TermsOfMembership.count') do
      post :create, terms_of_membership: { bill_type: @terms_of_membership.bill_type, club_id: @terms_of_membership.club_id, deleted_at: @terms_of_membership.deleted_at, enrollment_price: @terms_of_membership.enrollment_price, grace_period: @terms_of_membership.grace_period, max_reactivations: @terms_of_membership.max_reactivations, mode: @terms_of_membership.mode, needs_enrollment_approval: @terms_of_membership.needs_enrollment_approval, trial_days: @terms_of_membership.trial_days, year_price: @terms_of_membership.year_price }
    end

    assert_redirected_to terms_of_membership_path(assigns(:terms_of_membership))
  end

  test "should show terms_of_membership" do
    get :show, id: @terms_of_membership
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @terms_of_membership
    assert_response :success
  end

  test "should update terms_of_membership" do
    put :update, id: @terms_of_membership, terms_of_membership: { bill_type: @terms_of_membership.bill_type, club_id: @terms_of_membership.club_id, deleted_at: @terms_of_membership.deleted_at, enrollment_price: @terms_of_membership.enrollment_price, grace_period: @terms_of_membership.grace_period, max_reactivations: @terms_of_membership.max_reactivations, mode: @terms_of_membership.mode, needs_enrollment_approval: @terms_of_membership.needs_enrollment_approval, trial_days: @terms_of_membership.trial_days, year_price: @terms_of_membership.year_price }
    assert_redirected_to terms_of_membership_path(assigns(:terms_of_membership))
  end

  test "should destroy terms_of_membership" do
    assert_difference('TermsOfMembership.count', -1) do
      delete :destroy, id: @terms_of_membership
    end

    assert_redirected_to terms_of_memberships_path
  end
end
