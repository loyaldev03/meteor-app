require 'test_helper'

class CreditCardsControllerTest < ActionController::TestCase
  setup do
    @admin_user = FactoryGirl.create(:confirmed_admin_agent)
    @representative_user = FactoryGirl.create(:confirmed_representative_agent)
    @supervisor_user = FactoryGirl.create(:confirmed_supervisor_agent)
    @api_user = FactoryGirl.create(:confirmed_api_agent)
    @agency_agent = FactoryGirl.create(:confirmed_agency_agent)
    @terms_of_membership = FactoryGirl.create :terms_of_membership_with_gateway
    @club = @terms_of_membership.club
    @partner = @club.partner
    @saved_member = create_active_member(@terms_of_membership, :member_with_api)
    @active_credit_card = FactoryGirl.create :credit_card_master_card, :active => true, :member_id => @saved_member.id
    @credit_card_master_card_number = "5589548939080095"
    active_merchant_stubs_store(@credit_card_master_card_number)
    # request.env["devise.mapping"] = Devise.mappings[:agent]
  end

  def generate_post_message
    post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, member_prefix: @saved_member.visible_id, 
                  credit_card: { :number => @credit_card.number, :expire_month => @credit_card.expire_month, :expire_year => @credit_card.expire_year }
  end  

  test "Should add a new credit_card" do
  	sign_in @admin_user
    
    cc_number = @active_credit_card.number
    
    @credit_card = FactoryGirl.build :credit_card_american_express

    active_merchant_stubs_store(@credit_card.number)
   
    assert_difference('Operation.count',2) do
      assert_difference('CreditCard.count',1) do
        generate_post_message
      end
    end
    assert_response :redirect
    assert_equal(@saved_member.active_credit_card.number, nil)
    assert_equal(@saved_member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card.number])
    assert_equal(@saved_member.active_credit_card.expire_month, @credit_card.expire_month)
	end

  test "Should not add a new credit_card with different year, instead should update actual credit card" do
    sign_in @admin_user
    
    cc_number = @active_credit_card.number
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = @credit_card_master_card_number
    @credit_card.expire_month = @saved_member.active_credit_card.expire_month

    assert_difference('Operation.count') do
      assert_difference('CreditCard.count',0) do
        generate_post_message
      end
    end
    assert_response :redirect
    assert_equal(@saved_member.active_credit_card.number, nil)
    assert_equal(@saved_member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card_master_card_number])
    assert_equal(@saved_member.active_credit_card.expire_month, @credit_card.expire_month)
  end

  test "Should not add a new credit_card with different month, instead should update actual credit card" do
    sign_in @admin_user
        
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = @credit_card_master_card_number
    @credit_card.expire_year = @saved_member.active_credit_card.expire_year

    assert_difference('Operation.count') do
      assert_difference('CreditCard.count',0) do
        generate_post_message
      end
    end
    assert_response :redirect

    assert_equal(@saved_member.active_credit_card.number, nil)
    assert_equal(@saved_member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card_master_card_number])
    assert_equal(@saved_member.active_credit_card.expire_month, @credit_card.expire_month)
  end

  test "Should not add a new credit_card with invalid number" do
    sign_in @admin_user
    
    cc_token = @active_credit_card.token
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = "123456"

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_post_message
      end
    end
    assert_response :success
    assert_equal(@saved_member.active_credit_card.token, CREDIT_CARD_TOKEN[@credit_card_master_card_number])
  end
  
  test "Should not add new credit card with same data as the one active" do
    sign_in @admin_user
    
    cc_token = @active_credit_card.token

    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = @credit_card_master_card_number
    @credit_card.expire_year = @saved_member.active_credit_card.expire_year
    @credit_card.expire_month = @saved_member.active_credit_card.expire_month

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_post_message
      end
    end
    assert_response :redirect
    assert_equal(@saved_member.active_credit_card.token, cc_token)
    assert_equal(@saved_member.active_credit_card.expire_month, @credit_card.expire_month)
  end


  test "Should activate old credit when it is already created, if it is not expired and dates have changed" do
    sign_in @admin_user

    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:member_id => @saved_member.id
    cc_number = @credit_card.number
    cc_token = @credit_card.token
    @credit_card.expire_year = (Time.zone.now + 3.year).year
    @credit_card.expire_month = (Time.zone.now + 10.month).month

    active_merchant_stubs_store(cc_number)

    assert_difference('Operation.count',2) do
      assert_difference('CreditCard.count',0) do
        generate_post_message
      end
    end

    assert_response :redirect
    assert_equal(@saved_member.active_credit_card.number, nil)
    assert_equal(@saved_member.active_credit_card.token, cc_token)
  end


  test "Should activate old credit when it is already created, if it is not expired" do
    sign_in @admin_user

    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:member_id => @saved_member.id
    cc_token = @credit_card.token
    cc_number = @credit_card.number

    active_merchant_stubs_store(cc_number)

    assert_difference('Operation.count',1) do
      assert_difference('CreditCard.count',0) do
        generate_post_message
      end
    end

    assert_response :redirect
    assert_equal(@saved_member.active_credit_card.number, nil)
    assert_equal(@saved_member.active_credit_card.token, cc_token)
  end

  test "Should not activate old credit card when update only number, if old is expired" do
    sign_in @admin_user
    cc_token = @active_credit_card.token
    
    @credit_card = FactoryGirl.create :credit_card_american_express, :active => false ,:member_id => @saved_member.id
    @credit_card.expire_month = (Time.zone.now-1.month).month
    @credit_card.expire_year = (Time.zone.now-1.year).year

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_post_message
      end
    end
    assert_response :success
    assert_equal(@saved_member.active_credit_card.token, cc_token)
  end

  test "Should not update active credit card with expired month" do
    sign_in @admin_user 
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = @credit_card_master_card_number
    expire_month = Time.zone.now - 1.month
    @credit_card.expire_month = expire_month.month
    @credit_card.expire_year = expire_month.year 

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_post_message
      end
    end
    assert_response :success

    assert_equal(@saved_member.active_credit_card.number, nil)
    assert_not_equal(@saved_member.active_credit_card.expire_month, @credit_card.expire_month)
    assert_not_equal(@saved_member.active_credit_card.expire_year, @credit_card.expire_year)
  end

  test "Should not update active credit card with expired year" do
    sign_in @admin_user

    cc_token = @active_credit_card.token
    
    @credit_card = FactoryGirl.build :credit_card_american_express
    @credit_card.number = @credit_card_master_card_number
    @credit_card.expire_year = (Time.zone.now-2.year).year

    active_merchant_stubs_store(@credit_card.number)

    assert_difference('Operation.count',0) do
      assert_difference('CreditCard.count',0) do
        generate_post_message
      end
    end
    assert_response :success

    assert_equal(@saved_member.active_credit_card.number, nil)
    assert_equal(@saved_member.active_credit_card.token, cc_token)
    assert_not_equal(@saved_member.active_credit_card.expire_year, @credit_card.expire_year)
  end

end
