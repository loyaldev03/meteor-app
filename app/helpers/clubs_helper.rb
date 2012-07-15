module ClubsHelper

  def theme_switcher(f)
    f.select :theme, ['application', 'readable', 'united']
  end

end
