module DomainsHelper
	def generate_select_club_id(f,domain,clubs)
	  f.collection_select :club_id, clubs, "id", "name", :include_blank => ''
	end
end


