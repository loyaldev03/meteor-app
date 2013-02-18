module DomainsHelper

  def generate_select_club_id(f,domain,clubs, setted = false)
  	if setted
			f.collection_select :club_id, [domain.club], "id", "name"
		else
			f.collection_select :club_id, clubs, "id", "name", :include_blank => ''
  	end
  end

end


