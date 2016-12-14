Turnout.configure do |config|
  config.maintenance_pages_path = config.app_root.join('public').join( Rails.env.production? ? 'maintenance' : 'maintenance_test').to_s
end