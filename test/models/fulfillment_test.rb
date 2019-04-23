require 'test_helper'

class FulfillmentTest < ActiveSupport::TestCase
  setup do
    @club                  = FactoryBot.create(:simple_club_with_gateway)
    @product_with_stock    = FactoryBot.create(:product, club_id: @club.id, sku: 'PRODUCT')
    @product_without_stock = FactoryBot.create(:product_without_stock_and_not_recurrent, club_id: @club.id, sku: 'NOSTOCK')
    @product_recurrent     = FactoryBot.create(:product_with_recurrent, club_id: @club.id, sku: 'NORECURRENT')
    @user                  = FactoryBot.create(:user, club: @club)
    @fulfillment           = FactoryBot.create(:fulfillment, user: @user, club: @club, product: @product_with_stock)
  end

  test 'Assign default information upon creation' do
    assert_equal @fulfillment.assigned_at.to_date, Time.zone.now.to_date
    assert_equal @fulfillment.tracking_code, "#{@club.fulfillment_tracking_prefix}#{@user.id}"
    assert_equal @fulfillment.full_name, "#{@user.last_name}, #{@user.first_name}, (#{@user.state})"
    assert_equal @fulfillment.full_address, [@user.address, @user.city, @user.zip].join(', ')
    full_phone_number_value = [@user.phone_country_code, @user.phone_area_code, @user.phone_local_number].join(', ')
    assert_equal @fulfillment.full_phone_number, (full_phone_number_value.length > 7 ? full_phone_number_value : nil)
  end

  test 'Updating fulfillment as canceled replenish stock' do
    prev_stock = @fulfillment.product.stock
    assert_equal @fulfillment.status, 'not_processed'

    @fulfillment.update_status(nil, 'canceled', 'testing')
    assert_equal @fulfillment.reload.status, 'canceled'
    assert_equal @fulfillment.product.reload.stock, prev_stock + 1
  end

  test 'Updating fulfillment as do_not_honor replenish stock' do
    prev_stock = @fulfillment.product.stock
    assert_equal @fulfillment.status, 'not_processed'

    @fulfillment.update_status(nil, 'do_not_honor', 'testing')
    assert_equal @fulfillment.reload.status, 'do_not_honor'
    assert_equal @fulfillment.product.reload.stock, prev_stock + 1
  end

  test 'Update status method should audit transition' do
    assert_difference('Operation.count') do
      @fulfillment.update_status(nil, 'in_process', 'testing')
      assert_not_nil @user.operations.where(operation_type: Settings.operation_types['from_not_processed_to_in_process'])
    end
  end

  test 'Update status method allow update update from not_processed to in_process' do
    assert @fulfillment.not_processed?
    answer = @fulfillment.update_status(nil, 'in_process', 'testing')
    assert_equal answer[:code], Settings.error_codes.success
    assert @fulfillment.in_process?
  end

  test 'Update status method should not update renewed fulfillments' do
    @fulfillment.update_attribute :renewed, true

    answer = @fulfillment.update_status(nil, 'in_process', 'testing')
    assert_equal answer[:code], Settings.error_codes.fulfillment_error
    assert_equal answer[:message], I18n.t('error_messages.fulfillment_is_renwed')
    assert @fulfillment.not_processed?
  end

  test 'Update status method should not allow blank new status' do
    answer = @fulfillment.update_status(nil, '', 'testing')
    assert_equal answer[:code], Settings.error_codes.fulfillment_error
    assert_equal answer[:message], I18n.t('error_messages.fulfillment_new_status_blank')
    assert @fulfillment.not_processed?
  end

  test 'Update status method should not allow same status update' do
    answer = @fulfillment.update_status(nil, @fulfillment.status, 'testing')
    assert_equal answer[:code], Settings.error_codes.fulfillment_error
    assert_equal answer[:message], I18n.t('error_messages.fulfillment_new_status_equal_to_old', fulfillment_sku: @fulfillment.product_sku)
    assert @fulfillment.not_processed?
  end

  test 'Update status method cannot update cancelled fulfillments' do
    @fulfillment.update_status(nil, 'canceled', 'testing')
    (Fulfillment.state_machines.first[1].states.map(&:name) - [:canceled]).each do |new_status|
      answer = @fulfillment.update_status(nil, new_status, 'testing')
      assert_equal answer[:code], Settings.error_codes.fulfillment_error
      assert_equal answer[:message], I18n.t('error_messages.fulfillment_cannot_be_recovered', fulfillment_sku: @fulfillment.product_sku)
      assert @fulfillment.canceled?
    end
  end

  test 'Update status method cannot update do_not_honor fulfillments' do
    @fulfillment.update_status(nil, 'do_not_honor', 'testing')
    (Fulfillment.state_machines.first[1].states.map(&:name) - [:do_not_honor]).each do |new_status|
      answer = @fulfillment.update_status(nil, new_status, 'testing')
      assert_equal answer[:code], Settings.error_codes.fulfillment_error
      assert_equal answer[:message], I18n.t('error_messages.fulfillment_cannot_be_recovered', fulfillment_sku: @fulfillment.product_sku)
      assert @fulfillment.do_not_honor?
    end
  end

  test 'Update status method allow manual_review_required to not_processed, canceled or do_not_honor' do
    %w[not_processed canceled do_not_honor].each do |status|
      @fulfillment.update_attribute :status, 'manual_review_required'
      answer = @fulfillment.update_status(nil, status, 'testing')
      assert_equal answer[:code], Settings.error_codes.success
      assert @fulfillment.status == status
    end
  end

  test 'Update status method DO NOT allow manual_review_required to different status than not_processed, canceled or do_not_honor' do
    @fulfillment.update_status(nil, 'manual_review_required', 'testing')

    (Fulfillment.state_machines.first[1].states.map(&:name) - %i[not_processed canceled do_not_honor]).each do |new_status|
      answer = @fulfillment.update_status(nil, new_status, 'testing')
      assert_equal answer[:message], I18n.t('error_messages.fulfillment_invalid_transition')
      assert_equal answer[:code], Settings.error_codes.fulfillment_error
      assert @fulfillment.manual_review_required?
    end
  end

  test 'Update status method allow not_processed to do_not_honor' do
    answer = @fulfillment.update_status(nil, 'do_not_honor', 'testing')
    assert_equal answer[:code], Settings.error_codes.success
    assert @fulfillment.do_not_honor?
  end

  test 'Update status method allow manual_review_required to do_not_honor' do
    @fulfillment.update_status(nil, 'manual_review_required', 'testing')

    answer = @fulfillment.update_status(nil, 'do_not_honor', 'testing')
    assert_equal answer[:code], Settings.error_codes.success
    assert @fulfillment.do_not_honor?
  end

  test 'Update status method DO NOT allow non manual_review_required or not_process to do_not_honor' do
    (Fulfillment.state_machines.first[1].states.map(&:name) - %i[manual_review_required not_processed canceled do_not_honor]).each do |old_status|
      @fulfillment.update_attribute :status, old_status
      answer = @fulfillment.update_status(nil, 'do_not_honor', 'testing')
      assert_equal answer[:message], I18n.t('error_messages.fulfillment_invalid_transition')
      assert_equal answer[:code], Settings.error_codes.fulfillment_error
      assert @fulfillment.status.to_s == old_status.to_s
    end
  end

  test 'Update status method requires reason if new status is bad_address' do
    answer = @fulfillment.update_status(nil, 'bad_address')
    assert_equal answer[:message], I18n.t('error_messages.fulfillment_reason_blank')
    assert_equal answer[:code], Settings.error_codes.fulfillment_reason_blank
    assert @fulfillment.not_processed?

    answer = @fulfillment.update_status(nil, 'bad_address', 'testing')
    assert_equal answer[:code], Settings.error_codes.success
    assert @fulfillment.bad_address?
  end

  test 'Update status method marks user as wrong address when updating to bad_address' do
    reason = 'testing'
    answer = @fulfillment.update_status(nil, 'bad_address', reason)
    assert_equal answer[:code], Settings.error_codes.success
    assert @fulfillment.bad_address?
    assert_equal @user.wrong_address, reason
  end
end
