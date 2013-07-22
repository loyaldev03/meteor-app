@TOM_BASE_ID = 35

def create_tom(amount, tom_base)
  new_tom = TermsOfMembership.new(
    :name => "Annual $#{amount}", # Annual $monto
    :description => 'Annual $#{amount} Membership', # name + ' Membership'
    :club_id => 1, # Nascar
    :provisional_days => 30, # days of review
    :mode => 'production',
    :needs_enrollment_approval => 0,
    :installment_amount => amount, # amount
    :installment_type => '1.year',
    :club_cash_amount => 150,
    :quota => 12,
    :api_role => '91284557' # ONMC Drupal api id.
  )
  new_tom.save
  
  tom_base.email_templates.each do |et|
    new_et = et.dup
    new_et.terms_of_membership_id = new_tom.id
    new_et.save
  end
end

tom_base = TermsOfMembership.find(@TOM_BASE_ID)

[89,87,94,97,99,74,77,79].each do |amount|
  create_tom(amount, tom_base)
end