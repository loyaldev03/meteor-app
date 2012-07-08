module ClubsHelper

  def theme_switcher(f)
    f.select :theme, ['application', 'theme1', 'theme2', 'theme3']
  end

end
