module DomainsHelper
  
  def generate_select_club_id (f,domain,club)
  	f.select :club_id, options_from_collection_for_select(club, "id", "name"), :include_blank => ''
  end

end


