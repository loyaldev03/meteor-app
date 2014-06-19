module DomainsHelper
	def generate_select_club_id(f,domain,clubs,allow_blank=true)
		if allow_blank
		  f.collection_select :club_id, clubs, "id", "name", :include_blank => ''
		else
			f.collection_select :club_id, clubs, "id", "name"
		end
	end
end


