require 'test_helper'

class PaymentGatewayConfigurationTest < ActiveSupport::TestCase
  def setup
    @club                          = FactoryBot.create(:club)
    @payment_gateway_configuration = FactoryBot.build(:payment_gateway_configuration, club_id: @club.id)
  end

  test 'Saves PaymentGatewayConfiguration with all basic data' do
    assert @payment_gateway_configuration.save
  end

  test 'Does not allow to save PaymentGatewayConfiguration without login' do
    @payment_gateway_configuration.login = nil
    assert !@payment_gateway_configuration.save
    assert @payment_gateway_configuration.errors[:login].include? "can't be blank"
  end

  test 'Does not allow to save PaymentGatewayConfiguration without password' do
    @payment_gateway_configuration.password = nil
    assert !@payment_gateway_configuration.save
    assert @payment_gateway_configuration.errors[:password].include? "can't be blank"
  end

  test 'Does not allow to save PaymentGatewayConfiguration without gateway' do
    @payment_gateway_configuration.gateway = nil
    assert !@payment_gateway_configuration.save
    assert @payment_gateway_configuration.errors[:gateway].include? "can't be blank"
  end

  test 'Saves PaymentGatewayConfiguration without merchant_key' do
    @payment_gateway_configuration.merchant_key = nil
    assert @payment_gateway_configuration.save
  end

  test 'Does not allow to save PaymentGatewayConfiguration without merchant_key and payment gateway litle' do
    @payment_gateway_configuration.gateway      = 'litle'
    @payment_gateway_configuration.merchant_key = nil
    assert !@payment_gateway_configuration.save
    assert @payment_gateway_configuration.errors[:merchant_key].include? "can't be blank"
  end

  test 'Allow to save PaymentGatewayConfiguration with duplicated gateway in different club' do
    assert @payment_gateway_configuration.save
    @another_club = FactoryBot.create(:club)
    @another_pgc  = FactoryBot.build(:payment_gateway_configuration, club_id: @another_club.id)
    assert @another_pgc.save
  end

  test 'Does not allow to save PaymentGatewayConfiguration with duplicated gateway within the same club' do
    assert @payment_gateway_configuration.save
    @another_pgc = FactoryBot.build(:payment_gateway_configuration, club_id: @club.id)
    assert !@another_pgc.save
    assert @another_pgc.errors[:gateway].include? 'already created. There is a payment gateway already configured for this gateway.'
  end

  test 'Does not allow more than one PaymentGatewayConfiguration within a club' do
    assert @payment_gateway_configuration.save
    @another_pgc = FactoryBot.build(:litle_payment_gateway_configuration, club_id: @club.id)
    assert !@another_pgc.save
    assert @another_pgc.errors[:base].first[:error].include? "There is already one payment gateway configuration active on that club #{@club_id}"
  end
end
