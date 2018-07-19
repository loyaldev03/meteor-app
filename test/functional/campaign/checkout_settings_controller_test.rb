require 'test_helper'

class Campaigns::CheckoutSettingsControllerTest < ActionController::TestCase
  def setup
    @partner = FactoryBot.create(:partner)
    @club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    @tom = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @club.id)
    @campaign = FactoryBot.create(
      :campaign_with_checkout_settings,
      club_id: @club.id,
      terms_of_membership_id: @tom.id
    )
    @campaign_without_checkout_settings = FactoryBot.create(
      :campaign,
      club_id: @club.id,
      terms_of_membership_id: @tom.id
    )
    @another_club = FactoryBot.create(:simple_club_with_gateway, partner_id: @partner.id)
    @another_tom = FactoryBot.create(:terms_of_membership_with_gateway, club_id: @another_club.id)
    @another_campaign = FactoryBot.create(
      :campaign_with_checkout_settings,
      club_id: @another_club.id,
      terms_of_membership_id: @another_tom.id
    )
  end

  def sign_agent_with_global_role(type)
    @agent = FactoryBot.create type
    sign_in @agent
  end

  def sign_agent_with_club_role(type, role)
    @agent = FactoryBot.create(type, roles: '')
    ClubRole.create(club_id: @club.id, agent_id: @agent.id, role: role)
    sign_in @agent
  end

  def submit_form(campaign, values)
    post :update, partner_prefix: campaign.club.partner.prefix,
                  club_prefix: campaign.club.name,
                  campaign_id: campaign.id,
                  campaign: values
  end

  # Global Roles

  test 'global agents that should access all checkout settings pages' do
    %i[confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :show, partner_prefix: @partner.prefix, club_prefix: @club.name, campaign_id: @campaign.id
        assert_response :success, "#{agent} should access show page"
        get :edit, partner_prefix: @partner.prefix, club_prefix: @club.name, campaign_id: @campaign.id
        assert_response :success, "#{agent} should access edit page"
        delete :destroy, partner_prefix: @partner.prefix, club_prefix: @club.name, campaign_id: @campaign.id
        assert_response :redirect, "#{agent} should clear all checkout settings"
      end
    end
  end

  test 'global agents that should not access all checkout settings pages' do
    %i[confirmed_supervisor_agent
       confirmed_representative_agent
       confirmed_api_agent
       confirmed_fulfillment_manager_agent
       confirmed_agency_agent
       confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        get :show, partner_prefix: @partner.prefix, club_prefix: @club.name, campaign_id: @campaign.id
        assert_response :unauthorized, "#{agent} should not access show page"
        get :edit, partner_prefix: @partner.prefix, club_prefix: @club.name, campaign_id: @campaign.id
        assert_response :unauthorized, "#{agent} should not access edit page"
        delete :destroy, partner_prefix: @partner.prefix, club_prefix: @club.name, campaign_id: @campaign.id
        assert_response :unauthorized, "#{agent} should not clear all checkout settings"
      end
    end
  end

  test 'global agents that should update checkout settings' do
    %i[confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        updated_css_style = 'p { font-weight: "normal"; }'
        submit_form(@campaign, css_style: updated_css_style)
        assert_equal updated_css_style, Campaign.find(@campaign.id).css_style
      end
    end
  end

  test 'global agents that should destroy checkout settings' do
    %i[confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        delete :destroy, partner_prefix: @club.partner.prefix,
                         club_prefix: @club.name,
                         campaign_id: @campaign.id,
                         format: :json
        assert_response :redirect, "#{agent} should destroy checkout settings"
        assert_nil Campaign.find(@campaign.id).css_style
      end
    end
  end

  test 'global agents that should not destroy checkout settings' do
    %i[confirmed_supervisor_agent
       confirmed_representative_agent
       confirmed_api_agent
       confirmed_fulfillment_manager_agent
       confirmed_agency_agent
       confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        delete :destroy, partner_prefix: @club.partner.prefix,
                         club_prefix: @club.name,
                         campaign_id: @campaign.id,
                         format: :json
        assert_response :unauthorized, "#{agent} should not destroy checkout settings"
        assert_not_nil Campaign.find(@campaign.id).css_style
      end
    end
  end

  test 'global agents should remove images' do
    %i[confirmed_admin_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        %w[header_image_url result_pages_image_url].each do |image_name|
          delete :remove_image, partner_prefix: @club.partner.prefix,
                                club_prefix: @club.name,
                                campaign_id: @campaign.id,
                                image_name: image_name
          assert_response :redirect, "#{agent} should remove image #{image_name}"
        end
      end
    end
  end

  test 'global agents should not remove images' do
    %i[confirmed_supervisor_agent
       confirmed_representative_agent
       confirmed_api_agent
       confirmed_fulfillment_manager_agent
       confirmed_agency_agent
       confirmed_landing_agent].each do |agent|
      sign_agent_with_global_role(agent)
      perform_call_as(@agent) do
        %w[header_image_url result_pages_image_url].each do |image_name|
          delete :remove_image, partner_prefix: @club.partner.prefix,
                                club_prefix: @club.name,
                                campaign_id: @campaign.id,
                                image_name: image_name
          assert_response :unauthorized, "#{agent} should not remove image #{image_name}"
        end
      end
    end
  end

  # Club Roles

  test 'club admin agent should access all checkout settings pages' do
    role = :admin
    sign_agent_with_club_role(:agent, role)
    perform_call_as(@agent) do
      get :show, partner_prefix: @partner.prefix, club_prefix: @club.name, campaign_id: @campaign.id
      assert_response :success, "#{role} agent should access show page"
      get :edit, partner_prefix: @partner.prefix, club_prefix: @club.name, campaign_id: @campaign.id
      assert_response :success, "#{role} agent should access edit page"
      delete :destroy, partner_prefix: @partner.prefix, club_prefix: @club.name, campaign_id: @campaign.id
      assert_response :redirect, "#{role} agent should clear all checkout settings"
    end
  end

  test 'club agents that should not access checkout settings pages' do
    %i[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :show, partner_prefix: @partner.prefix, club_prefix: @club.name, campaign_id: @campaign.id
        assert_response :unauthorized, "#{role} agent should not access show page"
        get :edit, partner_prefix: @partner.prefix, club_prefix: @club.name, campaign_id: @campaign.id
        assert_response :unauthorized, "#{role} agent should not access edit page"
        delete :destroy, partner_prefix: @partner.prefix, club_prefix: @club.name, campaign_id: @campaign.id
        assert_response :unauthorized, "#{role} agent should not clear all checkout settings"
      end
    end
  end

  test 'club agents that should not access checkout settings pages from another club' do
    %i[admin supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        get :show, partner_prefix: @partner.prefix, club_prefix: @another_club.name, campaign_id: @another_campaign.id
        assert_response :unauthorized, "#{role} agent should not access show page of another club"
        get :edit, partner_prefix: @partner.prefix, club_prefix: @another_club.name, campaign_id: @another_campaign.id
        assert_response :unauthorized, "#{role} agent should not access edit page of another club"
        delete :destroy, partner_prefix: @partner.prefix, club_prefix: @another_club.name, campaign_id: @another_campaign.id
        assert_response :unauthorized, "#{role} agent should not clear all checkout settings of another club"
      end
    end
  end

  test 'club admin agents should update checkout settings' do
    role = :admin
    sign_agent_with_club_role(:agent, role)
    perform_call_as(@agent) do
      values = {
        checkout_page_bonus_gift_box_content: 'new bonus gift box content',
        checkout_page_footer: 'page footer',
        css_style: 'p { font-weight: "bold"; }',
        duplicated_page_content: 'duplicated page content',
        error_page_content: 'error_page_content',
        result_page_footer: 'result_page_footer',
        thank_you_page_content: 'thank_you_page_content',
        header_image_url: Rack::Test::UploadedFile.new(Rails.root.join('test', 'fixtures', 'images', 'image.png')),
        result_pages_image_url: Rack::Test::UploadedFile.new(Rails.root.join('test', 'fixtures', 'images', 'image.png'))
      }
      submit_form(@campaign_without_checkout_settings, values)
      campaign = Campaign.find(@campaign_without_checkout_settings.id)
      assert_response :redirect, "#{role} agent should update checkout settings"
      assert_equal 'new bonus gift box content', campaign.checkout_page_bonus_gift_box_content
    end
  end

  test 'club agents that should not update checkout settings' do
    updated_css_style = 'p { font-weight: "normal"; }'
    %i[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        submit_form(@campaign, css_style: updated_css_style)
        assert_response :unauthorized, "#{role} agent should not update checkout settings"
        assert_not_equal updated_css_style, @campaign.css_style
      end
    end
  end

  test 'club agents that should not update checkout settings from another club' do
    updated_css_style = 'p { font-weight: "normal"; }'
    %i[admin supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        submit_form(@another_campaign, css_style: updated_css_style)
        assert_response :unauthorized, "#{role} agent should not update checkout settings from another club"
        assert_not_equal updated_css_style, @campaign.css_style
      end
    end
  end

  test 'club admin agents should destroy checkout settings' do
    role = :admin
    sign_agent_with_club_role(:agent, role)
    perform_call_as(@agent) do
      delete :destroy, partner_prefix: @club.partner.prefix,
                       club_prefix: @club.name,
                       campaign_id: @campaign.id,
                       format: :json
      assert_response :redirect, "#{role} agent should destroy checkout settings"
      assert_nil Campaign.find(@campaign.id).css_style
    end
  end

  test 'club agents that should not destroy checkout settings' do
    %i[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        delete :destroy, partner_prefix: @club.partner.prefix,
                         club_prefix: @club.name,
                         campaign_id: @campaign.id
        assert_response :unauthorized, "#{role} agent should not destroy checkout settings"
        assert_not_nil Campaign.find(@campaign.id).css_style
      end
    end
  end

  test 'club agents that should not destroy checkout settings from another club' do
    %i[admin supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        delete :destroy, partner_prefix: @club.partner.prefix,
                         club_prefix: @another_club.name,
                         campaign_id: @another_campaign.id
        assert_response :unauthorized, "#{role} agent should not destroy checkout settings from another club"
        assert_not_nil Campaign.find(@campaign.id).css_style
      end
    end
  end

  test 'club admin agents should remove images' do
    role = :admin
    sign_agent_with_club_role(:agent, role)
    perform_call_as(@agent) do
      %w[header_image_url result_pages_image_url].each do |image_name|
        delete :remove_image, partner_prefix: @club.partner.prefix,
                              club_prefix: @club.name,
                              campaign_id: @campaign.id,
                              image_name: image_name
        assert_response :redirect, "#{role} agent should remove image #{image_name}"
      end
    end
  end

  test 'club agents that should not remove images' do
    %i[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        %w[header_image_url result_pages_image_url].each do |image_name|
          delete :remove_image, partner_prefix: @club.partner.prefix,
                                club_prefix: @club.name,
                                campaign_id: @campaign.id,
                                image_name: image_name
          assert_response :unauthorized, "#{role} agent should not remove image #{image_name}"
        end
      end
    end
  end

  test 'club agents that should not remove images from another club' do
    %i[supervisor representative api agency fulfillment_managment landing].each do |role|
      sign_agent_with_club_role(:agent, role)
      perform_call_as(@agent) do
        %w[header_image_url result_pages_image_url].each do |image_name|
          delete :remove_image, partner_prefix: @club.partner.prefix,
                                club_prefix: @another_club.name,
                                campaign_id: @another_campaign.id,
                                image_name: image_name
          assert_response :unauthorized, "#{role} agent should not remove image #{image_name} from another club"
        end
      end
    end
  end
end
