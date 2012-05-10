class CreateEmailTemplates < ActiveRecord::Migration
  def change
    create_table :email_templates do |t|
      t.string :name
      t.string :client # lyris - ActionMailer - Amazon
      t.string :external_id #lyris will store trigger and mlid
      t.string :template_type
      t.integer :terms_of_membership_id, :limit => 8
      t.timestamps
    end

    # setup action mailer as default on each TermsOfMembership
    TermsOfMembership.all.each do |tom|
      EmailTemplate::TEMPLATE_TYPES.each do |type|
        et = EmailTemplate.new 
        et.name = "Test #{type}"
        et.client = :action_mailer
        et.template_type = type
        et.terms_of_membership_id = tom.id
        et.save
      end
    end
  end
end
