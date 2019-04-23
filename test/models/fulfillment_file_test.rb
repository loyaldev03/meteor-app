class FulfillmentFileTest < ActiveSupport::TestCase
  def setup
    @club                 = FactoryBot.create(:simple_club_with_gateway)
    @terms_of_membership  = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    active_merchant_stubs_payeezy
  end

  def create_fulfillment_file(fulfillments)
    FulfillmentFile.create agent: nil,
                           product: 'sloops',
                           club: @club,
                           fulfillments: fulfillments
  end

  test 'Mark fulfillments related when updating status from in_process to sent' do
    user        = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    second_user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    fulfillment_file = FactoryBot.create(:fulfillment_file, agent: nil,
                                                            product: 'sloops',
                                                            club: @club,
                                                            fulfillments: [user.fulfillments.first, second_user.fulfillments.first])
    fulfillment_file.mark_fulfillments_as_in_process
    fulfillment_file.processed
    fulfillment_file.reload.fulfillments.each { |fulfillment| assert fulfillment.sent? }
  end

  test 'Mark fulfillments related when updating status from packed to sent' do
    user        = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    second_user = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    fulfillment_file = FactoryBot.create(:fulfillment_file, agent: nil,
                                                            product: 'sloops',
                                                            club: @club,
                                                            fulfillments: [user.fulfillments.first, second_user.fulfillments.first])
    fulfillment_file.mark_fulfillments_as_in_process
    fulfillment_file.pack
    fulfillment_file.processed_and_packed
    fulfillment_file.reload.fulfillments.each { |fulfillment| assert fulfillment.sent? }
  end

  test 'Generate CSV including only related fulfillments' do
    user                = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    second_user         = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    third_user          = enroll_user(FactoryBot.build(:user), @terms_of_membership)
    fulfillment         = user.fulfillments.first
    second_fulfillment  = second_user.fulfillments.first
    fulfillment_file = FactoryBot.create(:fulfillment_file, agent: nil,
                                                            product: 'sloops',
                                                            club: @club,
                                                            fulfillments: [fulfillment, second_fulfillment])
    fulfillment_file.mark_fulfillments_as_in_process

    file = fulfillment_file.generateXLS(false)

    ['PackageId', 'Costcenter', 'Companyname', 'Address', 'City', 'State', 'Zip', 'Endorsement', 'Packagetype', 'Divconf', 'Bill Transportation', 'Weight', 'Return Service Requested', 'Irregulars', 'Y', 'Shipper', 'MID'].each do |field|
      file.inspect.to_s.include? field
    end
    [fulfillment, second_fulfillment].each do |f|
      ["UPS Service\n#{f.tracking_code}", f.product_sku.to_s, f.user.full_name.to_s, f.user.address.to_s, f.user.city.to_s, f.user.state.to_s, f.user.zip.to_s].each do |field|
        file.inspect.to_s.include? field
      end
    end
    assert file.inspect.to_s.exclude? "UPS Service\n#{third_user.fulfillments.first.tracking_code}"
  end
end
