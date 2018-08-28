require 'ruby-jmeter'

UNBOUNCE_LANDING_PAGE = 'https://offer.onmc.com/traveltumbler_v2/'.freeze

test do
  cache clear_each_iteration: true

  cookies

  threads count: 100, duration: 1200 do
    transaction 'landing_page' do
      visit name: 'Landing Page', url: UNBOUNCE_LANDING_PAGE
    end
  end
end.jmx(file: 'landing_page.jmx')
