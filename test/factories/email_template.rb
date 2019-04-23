FactoryBot.define do

  factory :email_template, class: EmailTemplate do
    sequence(:name) { |n| "test_communication_#{n}" }
    client { 'exact_target' }
    template_type { 'pillar' }
    days { 5 }
    external_attributes { '---\n:trigger_id: 12345\n:mlid: 23456\n:site_id: 34567\n:customer_key: 45678\n' }
  end

  factory :email_template_for_exact_target, class: EmailTemplate do
    sequence(:name) { |n| "test_communication_#{n}" }
    client { 'exact_target' }
    template_type { 'pillar' }
    days { 12 }
    external_attributes { '---\n:trigger_id: 12345\n:mlid: 23456\n:site_id: 34567\n:customer_key: 45678\n' }
  end

  factory :email_template_for_action_mailer, class: EmailTemplate do
    sequence(:name) { |n| "test_communication_action_mailer_#{n}" }
    client { 'action_mailer' }
    template_type { 'pillar' }
    days { 12 }
    external_attributes { '' }
  end

  factory :email_template_for_mailchimp_mandrill, class: EmailTemplate do
    sequence(:name) { |n| "test_communication_#{n}" }
    client { 'mailchimp_mandrill' }
    template_type { 'pillar' }
    days { 12 }
    external_attributes { { template_name: 12345 } }
  end

  factory :mailchimp_mandrill_refund_template, parent: :email_template_for_mailchimp_mandrill do
    template_type { 'refund' }
  end
end
