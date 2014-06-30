# encoding: utf-8
require 'test_helper'

class EmailTemplateTest < ActiveSupport::TestCase

  setup do
  	@admin_agent = FactoryGirl.create(:confirmed_admin_agent)
    @current_agent = FactoryGirl.create(:agent)
    @club = FactoryGirl.create(:simple_club_with_gateway)
    @member = FactoryGirl.build(:member)
    @credit_card = FactoryGirl.build(:credit_card)
    @tom = FactoryGirl.create(:terms_of_membership_with_gateway, :club_id => @club.id, :name => 'TOM for Email Templates Test')
    @communication = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom.id)
  end

	test 'Do not allow enter member communication duplicate where it is not Pillar type - Logged by General Admin' do
		old_comm = EmailTemplate.where(:terms_of_membership_id => @tom.id, :template_type => 'birthday').first
		if old_comm
			old_comm.destroy
		end
		old_comm = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom.id, :template_type => 'birthday')
		old_comm.save
		sign_in(@admin_agent)
		comm = FactoryGirl.create(:email_template, :terms_of_membership_id => @tom.id)
		post :create, partner_prefix: @partner.prefix, club_prefix: @club.name, subscription_plans: @tom.id, email_template: { 
			name: comm.name, client: comm.client, external_attributes: comm.external_attributes, terms_of_membership_id: @tom.id, template_type: 'birthday' }
		assert_response :success  
	end










end