FactoryGirl.define do

  factory :email_template, class: EmailTemplate do
    sequence(:name) {|n| "test_communication_#{n}"}
    client 'exact_target'
    template_type 'pillar'
    days_after_join_date 5
    external_attributes '---\n:trigger_id: 12345\n:mlid: 23456\n:site_id: 34567\n:customer_key: 45678\n'
  end

  factory :email_template_for_action_mailer, class: EmailTemplate do
    sequence(:name) {|n| "test_communication_action_mailer_#{n}"}
    client 'action_mailer'
    template_type 'pillar'
    days_after_join_date 5
    external_attributes ''
  end
end