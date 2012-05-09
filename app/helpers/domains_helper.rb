module DomainsHelper
  
  def generate_select_club_id (f,domain,clubs)
  	f.select :club_id, options_from_collection_for_select(clubs, "id", "name"), :include_blank => ''
  end

end


