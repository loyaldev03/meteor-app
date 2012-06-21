CanTango.config do |config|
  config.engines.all :on

  config.engine(:permit) do |engine|
    engine.set :on
    engine.mode = :no_cache # caching is not working
  end  
  config.engine(:permission).set :off
end
