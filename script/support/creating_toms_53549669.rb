def create_tom(amount)
	TermsOfMemberships.new(
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
	).save
end



[89,87,94,97,99,74,77,79].each do |amount|
	create_tom(amount)
end