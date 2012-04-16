module ClubsHelper

  def generate_select_partner_id (f,domain,partner)
  	f.select :partner_id, options_from_collection_for_select(partner, "id", "name")
  end


end
