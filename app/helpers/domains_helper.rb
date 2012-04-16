module DomainsHelper
  
  def generate_select_partners_id (domain,partner)
    select_tag :partner_id, options_from_collection_for_select(partner, "id", "name")
  end

  def generate_select_club_id (domain,club)
  	select_tag :club_id, options_from_collection_for_select(club, "id", "name")
  end

end


