module DomainsHelper
  
  def generate_select_partners_id (domain,partner)
    select_tag :partner_id, options_from_collection_for_select(partner, "id", "name")
  end
end


